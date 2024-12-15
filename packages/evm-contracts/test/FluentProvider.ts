import { expect } from "chai";
import { ethers, upgrades } from "hardhat";
import { FluentProvider, FluentProvider__factory } from "../typechain-types";
import { Interval, Signer } from "./types";
import { BucketStruct } from "../typechain-types/contracts/FluentProvider";
import { provider, signers, abi } from './utils'
import { getToken, getUnderlying } from "./utils/token";
import { getBucket } from "./utils/provider";

describe("FluentProvider", function () {
    const ZERO_ADDRESSS = ethers.ZeroAddress;
    const TOKEN_ADDRESS = ethers.hexlify(ethers.randomBytes(20)).toLowerCase();

    // const BUCKETS: BucketStruct = {
    //     token: TOKEN_ADDRESS,
    //     interval: 2,
    //     amount: 32n,
    // }

    let bucket: BucketStruct;
    let bucketId: string;

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
        contractAddress = await contract.getAddress()

        bucket = getBucket(TOKEN_ADDRESS, Interval.Monthly);
        bucketId = `${ethers.keccak256(abi.encode(["address", "bytes4"], [bucket.token, bucket.group]))}`.slice(0, 10);

        await contract.openProvider(provider.validName, [bucket]);

        providerId = ethers.keccak256(abi.encode(["address", "string"], [account.address, provider.validName]))
    });

    describe("Initialization", function () {
        it("# 1.1 Should correctly set provider data", async function () {
            let data = await contract.getProvider(providerId)

            expect(data.name).to.eq(provider.validName)
            expect(data.owner).to.eq(account.address)
        });

        it("# 1.2 Should revert with empty buckets", async function () {
            await expect(contract.openProvider(provider.validName, [])).to.be.revertedWithCustomError(contract, "ProviderBucketsInvalid");
        });

        it("# 1.3 Should revert with invalid name", async function () {
            await expect(contract.openProvider(provider.invalidName, [bucket])).to.be.revertedWithCustomError(contract, "ProviderNameInvalid");
            await expect(contract.openProvider("", [bucket])).to.be.revertedWithCustomError(contract, "ProviderNameInvalid");
        });

        it("# 1.4 Should revert if already exists", async function () {
            await expect(contract.openProvider(provider.validName, [bucket])).to.be.revertedWithCustomError(contract, "ProviderAlreadyExists");
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
            it("# 4.1.1 Should allow account to create a bucket", async function () {
                const token = ethers.hexlify(ethers.randomBytes(20))
                // const newBucketId = `${ethers.keccak256(abi.encode(["address", "uint64"], [token, bucket.interval]))}`.slice(0, 10);

                await expect(contract.createBucket(providerId, { ...bucket, token })).to.not.be.reverted
            });

            it("# 4.1.2 Should revert if attacker attempts to create a bucket", async function () {
                const token = ethers.hexlify(ethers.randomBytes(20))
                await expect(contract.connect(attacker.signer).createBucket(providerId, { ...bucket, token }))
                    .to.be.revertedWithCustomError(contract, 'ProviderUnauthorizedAccount').withArgs(attacker.address)
            });

            it("# 4.1.3 Should revert if provider does not exist", async function () {
                const provider = ethers.hexlify(ethers.randomBytes(32))

                await expect(contract.createBucket(provider, bucket))
                    .to.be.revertedWithCustomError(contract, 'ProviderDoesNotExist')
            });

            it("# 4.1.3 Should revert if bucket already exists", async function () {
                await expect(contract.createBucket(providerId, bucket))
                    .to.be.revertedWithCustomError(contract, 'BucketAlreadyExists')
            });
        });

        describe("Remove", function () {
            it("# 4.2.1 Should allow account to remove a bucket", async function () {
            });

            it("# 4.2.2 Should revert if attacker attempts to remove a bucket", async function () {
                //         // await expect(contract.connect(attacker.signer).addBucket(provider, name, interval))
                //         //     .to.be.revertedWithCustomError(contract, "ProviderUnauthorizedAccount").withArgs(attacker.address)
            });

            it("# 4.2.3 Should revert if provider does not exist", async function () {
                //         // let random = ethers.hexlify(ethers.randomBytes(32));

                //         // await expect(contract.addBucket(random, name, interval))
                //         //     .to.be.revertedWithCustomError(contract, "ProviderDoesNotExist");
            });

            it("# 4.2.3 Should revert if bucket does not exist", async function () {
                //         // let random = ethers.hexlify(ethers.randomBytes(32));

                //         // await expect(contract.addBucket(random, name, interval))
                //         //     .to.be.revertedWithCustomError(contract, "ProviderDoesNotExist");
            });
        })

        describe("Modify", function () {
            it("# 4.3.1 Should allow account to create bucket", async function () {

            });

            it("# 4.3.2 Should allow account to modify a bucket", async function () {

            });

            it("# 4.3.3 Should revert if provider does not exist", async function () {

            });
        })
    });
});
