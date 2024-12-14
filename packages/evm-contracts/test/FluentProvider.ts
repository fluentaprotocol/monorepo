import { expect } from "chai";
import { ethers, upgrades } from "hardhat";
import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
import { FluentProvider, FluentProvider__factory } from "../typechain-types";
import { Signer } from "./types";
import { BucketStruct } from "../typechain-types/contracts/FluentProvider";
import { provider, signers, abi } from './utils'

describe("FluentProvider", function () {
    const ZERO_ADDRESSS = ethers.ZeroAddress;
    const TOKEN_ADDRESS = ethers.hexlify(ethers.randomBytes(20)).toLowerCase();

    const BUCKETS: BucketStruct[] = [{
        token: TOKEN_ADDRESS,
        interval: 2,
        amount: 32n,
    }]

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

        await contract.openProvider(provider.validName, BUCKETS);

        providerId = ethers.keccak256(abi.encode(["address", "string"], [account.address, provider.validName]))
    });

    describe("Initialization", function () {
        it("# 1.1 Should correctly set provider data", async function () {
            let data = await contract.providerData(providerId)

            expect(data.name).to.eq(provider.validName)
            expect(data.owner).to.eq(account.address)
        });

        it("# 1.2 Should revert with empty buckets", async function () {
            await expect(contract.openProvider(provider.validName, [])).to.be.revertedWithCustomError(contract, "ProviderBucketsInvalid");
        });

        it("# 1.3 Should revert with invalid name", async function () {
            await expect(contract.openProvider(provider.invalidName, BUCKETS)).to.be.revertedWithCustomError(contract, "ProviderNameInvalid");
            await expect(contract.openProvider("", BUCKETS)).to.be.revertedWithCustomError(contract, "ProviderNameInvalid");
        });

        it("# 1.4 Should revert if already exists", async function () {
            await expect(contract.openProvider(provider.validName, BUCKETS)).to.be.revertedWithCustomError(contract, "ProviderAlreadyExists");
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

            const updated = await contract.providerData(providerId).then(x => x.owner)
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
        const name = "Basic";
        const interval = 48n * 60n * 60n;

        describe("Add", function () {
            it("# 4.1.1 Should allow account to create a bucket", async function () {
                //         await expect(contract.addBucket(provider, interval, TOKEN_ADDRESS, 2n)).to.not.be.reverted
            });

            it("# 4.1.2 Should revert if attacker attempts to create a bucket", async function () {
                //         await expect(contract.connect(attacker.signer).addBucket(provider, name, interval))
                //             .to.be.revertedWithCustomError(contract, "ProviderUnauthorizedAccount").withArgs(attacker.address)
            });

            it("# 4.1.3 Should revert if provider does not exist", async function () {
                //         let random = ethers.hexlify(ethers.randomBytes(32));

                //         await expect(contract.addBucket(random, name, interval))
                //             .to.be.revertedWithCustomError(contract, "ProviderDoesNotExist");
                //     });
            })

        });

        describe("Remove", function () {
            it("# 4.2.1 Should allow account to create bucket", async function () {
                //         // await expect(contract.addBucket(provider, name, interval)).to.not.be.reverted
            });

            it("# 4.2.2 Should revert if attacker attempts to create bucket", async function () {
                //         // await expect(contract.connect(attacker.signer).addBucket(provider, name, interval))
                //         //     .to.be.revertedWithCustomError(contract, "ProviderUnauthorizedAccount").withArgs(attacker.address)
            });

            it("# 4.2.3 Should revert if provider does not exist", async function () {
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
