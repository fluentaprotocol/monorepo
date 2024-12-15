import { expect } from "chai";
import { ethers, upgrades } from "hardhat";
import { FluentProvider, FluentProvider__factory } from "../typechain-types";
import { Interval, Signer } from "./types";
import { provider, signers, abi, unit } from './utils'
import { BucketStruct, EndpointStruct } from "../typechain-types/contracts/FluentProvider";
import { getBucket, getEndpoint } from "./utils/provider";

describe("FluentProvider", function () {
    const ZERO_ADDRESSS = ethers.ZeroAddress;
    const TOKEN_ADDRESS = ethers.hexlify(ethers.randomBytes(20)).toLowerCase();

    let bucketTag: string;
    let bucketData: BucketStruct;

    let endpointTag: string;
    let endpointData: EndpointStruct;

    let dao: Signer;
    let account: Signer;
    let account2: Signer;
    let attacker: Signer;

    let factory: FluentProvider__factory;
    let contract: FluentProvider;
    let contractAddress: string;

    let providerId: string;

    beforeEach(async function () {
        [dao, account, account2, attacker] = await signers.getSigners();

        factory = await ethers.getContractFactory("FluentProvider", dao.signer);
        contract = await upgrades.deployProxy(factory, {
            kind: 'uups',
            redeployImplementation: 'always'
        }).then(x => x.connect(account.signer)) as FluentProvider;
        contractAddress = await contract.getAddress();

        [bucketData, bucketTag] = getBucket(Interval.Monthly, "Fluenta");
        [endpointData, endpointTag] = getEndpoint(TOKEN_ADDRESS, bucketTag);

        await contract.openProvider(provider.validName, [bucketData], [endpointData]);

        providerId = ethers.keccak256(abi.encode(["address", "string"], [account.address, provider.validName]))
    });

    describe("Initialization", function () {
        it("# 1.1 Should correctly set provider data", async function () {
            let data = await contract.getProvider(providerId)

            expect(data.name).to.eq(provider.validName)
            expect(data.owner).to.eq(account.address)
        });

        it("# 1.2 Should revert with empty buckets", async function () {
            await expect(contract.openProvider(provider.validName, [], [])).to.be.revertedWithCustomError(contract, "ProviderBucketsInvalid");
        });

        it("# 1.3 Should revert with invalid name", async function () {
            await expect(contract.openProvider(provider.invalidName, [bucketData], [endpointData])).to.be.revertedWithCustomError(contract, "ProviderNameInvalid");
            await expect(contract.openProvider("", [bucketData], [endpointData])).to.be.revertedWithCustomError(contract, "ProviderNameInvalid");
        });

        it("# 1.4 Should revert if already exists", async function () {
            await expect(contract.openProvider(provider.validName, [bucketData], [endpointData])).to.be.revertedWithCustomError(contract, "ProviderAlreadyExists");
        });
    });

    describe("Termination", function () {
        it("# 2.1 Should allow account to close a provider", async function () {
            await expect(contract.closeProvider(providerId)).to.not.be.reverted;
        });

        it("# 2.2 Should revert if account is not the owner", async function () {
            await expect(contract.connect(attacker.signer).closeProvider(providerId))
                .to.be.revertedWithCustomError(contract, "ProviderUnauthorizedAccount").withArgs(attacker.address);
        });

        it("# 2.3 Should revert if provider does not exist", async function () {
            let random = ethers.hexlify(ethers.randomBytes(32));

            await expect(contract.closeProvider(random))
                .to.be.revertedWithCustomError(contract, "ProviderDoesNotExist");
        });
    });

    describe("Ownership", function () {
        it("# 3.1 Should allow account to transfer ownership of provider", async function () {
            await expect(contract.transferProvider(providerId, account2.address)).to.not.be.reverted;

            const updated = await contract.getProvider(providerId).then(x => x.owner)
            expect(updated).to.eq(account2.address)
        });

        it("# 3.2 Should revert transfer if new account is ZeroAddress", async function () {
            await expect(contract.transferProvider(providerId, ZERO_ADDRESSS))
                .to.be.revertedWithCustomError(contract, "ProviderInvalidAccount").withArgs(ZERO_ADDRESSS);
        });

        it("# 3.3 Should revert transfer if new account equals old account", async function () {
            await expect(contract.transferProvider(providerId, account.address))
                .to.be.revertedWithCustomError(contract, "ProviderInvalidAccount").withArgs(account.address);
        });

        it("# 3.4 Should revert transfer if called from non-owner address", async function () {
            await expect(contract.connect(attacker.signer).transferProvider(providerId, account2.address))
                .to.be.revertedWithCustomError(contract, "ProviderUnauthorizedAccount").withArgs(attacker.address);
        });

        it("# 3.5 Should revert if provider does not exist", async function () {
            let random = ethers.hexlify(ethers.randomBytes(32));

            await expect(contract.transferProvider(random, account2.address))
                .to.be.revertedWithCustomError(contract, "ProviderDoesNotExist");
        });
    });

    describe("Buckets", function () {
        describe("Create", function () {
            it("# 4.1.1 Should allow account to create buckets", async function () {
                await expect(contract.createBucket(providerId, { ...bucketData, name: "test" })).to.not.be.reverted
            });

            it("# 4.1.2 Should revert if non-owner attempts to create an endpoint", async function () {
                await expect(contract.connect(attacker.signer).createBucket(providerId, { ...bucketData, name: "test" }))
                    .to.be.revertedWithCustomError(contract, 'ProviderUnauthorizedAccount').withArgs(attacker.address)

            });

            it("# 4.1.3 Should revert if provider does not exist", async function () {
                let random = ethers.hexlify(ethers.randomBytes(32));

                await expect(contract.createBucket(random, { ...bucketData, name: "test" }))
                    .to.be.revertedWithCustomError(contract, 'ProviderDoesNotExist')
            });

            it("# 4.1.4 Should revert if bucket already exists", async function () {
                await expect(contract.createBucket(providerId, bucketData))
                    .to.be.revertedWithCustomError(contract, 'BucketAlreadyExists')
            });
        });

        describe("Remove", function () {
            let runBucket: BucketStruct;
            let runBucketTag: string;

            this.beforeEach(async function () {
                [runBucket, runBucketTag] = getBucket(Interval.Monthly, "Run");

                await contract.createBucket(providerId, runBucket);
            })

            it("# 4.2.1 Should allow account to remove a bucket", async function () {
                await expect(contract.removeBucket(providerId, runBucketTag)).to.not.be.reverted
            });

            it("# 4.2.2 Should revert if the bucket still has endpoints", async function () {
                // [ ] TODO still has to be implemented
            });

            it("# 4.2.3 Should revert if non-owner attempts to remove a bucket", async function () {
                await expect(contract.connect(attacker.signer).removeBucket(providerId, runBucketTag))
                    .to.be.revertedWithCustomError(contract, 'ProviderUnauthorizedAccount').withArgs(attacker.address)
            });

            it("# 4.2.4 Should revert if provider does not exist", async function () {
                let random = ethers.hexlify(ethers.randomBytes(32));

                await expect(contract.removeBucket(random, runBucketTag))
                    .to.be.revertedWithCustomError(contract, 'ProviderDoesNotExist')
            });

            it("# 4.2.5 Should revert if bucket does not exist", async function () {
                let random = ethers.hexlify(ethers.randomBytes(4));

                await expect(contract.removeBucket(providerId, random))
                    .to.be.revertedWithCustomError(contract, 'BucketDoesNotExist')
            });
        })

        describe("Rename", function () {
            const updated = "Updated";

            it("# 4.3.1 Should allow account to rename a buckewt", async function () {
                await expect(contract.renameBucket(providerId, bucketTag, updated)).to.not.be.reverted
            });

            it("# 4.3.2 Should revert if non-owner to rename a bucket", async function () {
                await expect(contract.connect(attacker.signer).renameBucket(providerId, bucketTag, updated))
                    .to.be.revertedWithCustomError(contract, 'ProviderUnauthorizedAccount').withArgs(attacker.address)
            });

            it("# 4.3.3 Should revert if bucket does not exists", async function () {
                let random = ethers.hexlify(ethers.randomBytes(4));
    
                await expect(contract.renameBucket(providerId, random, updated))
                    .to.be.revertedWithCustomError(contract, 'BucketDoesNotExist')
            });

            it("# 4.3.4 Should revert if provider does not exist", async function () {
                let random = ethers.hexlify(ethers.randomBytes(32));

                await expect(contract.renameBucket(random, bucketTag, updated))
                    .to.be.revertedWithCustomError(contract, 'ProviderDoesNotExist')
            });
        })
    });

    describe("Endpoints", function () {
        describe("Create", function () {
            it("# 5.1.1 Should allow account to create an endpoint", async function () {
                const token = ethers.hexlify(ethers.randomBytes(20))

                await expect(contract.createEndpoint(providerId, { ...endpointData, token })).to.not.be.reverted
            });

            it("# 5.1.2 Should revert if non-owner attempts to create an endpoint", async function () {
                const token = ethers.hexlify(ethers.randomBytes(20))
                await expect(contract.connect(attacker.signer).createEndpoint(providerId, { ...endpointData, token }))
                    .to.be.revertedWithCustomError(contract, 'ProviderUnauthorizedAccount').withArgs(attacker.address)
            });

            it("# 5.1.3 Should revert if provider does not exist", async function () {
                const provider = ethers.hexlify(ethers.randomBytes(32))

                await expect(contract.createEndpoint(provider, endpointData))
                    .to.be.revertedWithCustomError(contract, 'ProviderDoesNotExist')
            });

            it("# 5.1.3 Should revert if endpoint already exists", async function () {
                await expect(contract.createEndpoint(providerId, endpointData))
                    .to.be.revertedWithCustomError(contract, 'EndpointAlreadyExists')
            });
        });

        describe("Remove", function () {
            it("# 5.2.1 Should allow account to remove an endpoint", async function () {
                await expect(contract.removeEndpoint(providerId, endpointTag)).to.not.be.reverted
            });

            it("# 5.2.2 Should revert if non-owner attempts to remove an endpoint", async function () {
                await expect(contract.connect(attacker.signer).removeEndpoint(providerId, endpointTag))
                    .to.be.revertedWithCustomError(contract, 'ProviderUnauthorizedAccount').withArgs(attacker.address)
            });

            it("# 5.2.3 Should revert if provider does not exist", async function () {
                let random = ethers.hexlify(ethers.randomBytes(32));

                await expect(contract.removeEndpoint(random, endpointTag))
                    .to.be.revertedWithCustomError(contract, "ProviderDoesNotExist");
            });

            it("# 5.2.3 Should revert if endpoint does not exist", async function () {
                let random = ethers.hexlify(ethers.randomBytes(4));

                await expect(contract.removeEndpoint(providerId, random))
                    .to.be.revertedWithCustomError(contract, "EndpointDoesNotExist");
            });
        })

        describe("Modify", function () {
            it("# 5.3.1 Should allow account to modify an endpoint", async function () {
                await expect(contract.modifyEndpoint(providerId, endpointTag, unit.value(50, 6)))
                    .to.not.be.reverted;

            });

            it("# 5.3.2 Should revert if non-owner attempts to modify endpoint", async function () {
                await expect(contract.connect(attacker.signer).modifyEndpoint(providerId, endpointTag, unit.value(50, 6)))
                    .to.be.revertedWithCustomError(contract, 'ProviderUnauthorizedAccount').withArgs(attacker.address);
            });

            it("# 5.3.3 Should revert if endpoint does not exists", async function () {
                let random = ethers.hexlify(ethers.randomBytes(4));

                await expect(contract.modifyEndpoint(providerId, random, unit.value(50, 6)))
                    .to.be.revertedWithCustomError(contract, 'EndpointDoesNotExist');
            });

            it("# 5.3.4 Should revert if provider does not exist", async function () {
                let random = ethers.hexlify(ethers.randomBytes(32));

                await expect(contract.modifyEndpoint(random, endpointTag, unit.value(50, 6)))
                    .to.be.revertedWithCustomError(contract, 'ProviderDoesNotExist');
            });
        })
    });
});
