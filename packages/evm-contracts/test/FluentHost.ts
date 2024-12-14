import { expect } from "chai";
// import { ethers, upgrades } from "hardhat";
// import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
// import { FluentProvider__factory, FluentProvider, FluentHost__factory, FluentHost, Address } from "../typechain-types";
// import { deployHost, deployHostImplementation } from "./utils/deploy";

import { ethers, upgrades } from "hardhat";
import { FluentProvider, FluentProvider__factory, FluentHost, FluentHost__factory, FluentToken } from "../typechain-types";
import { Signer } from "./types";
import { signers, abi, provider, unit } from "./utils";
import { RpcBlockOutput } from "hardhat/internal/hardhat-network/provider/output";
import { JsonRpcBlock } from "hardhat-gas-reporter/dist/types";
import { getToken, getUnderlying } from "./utils/token";
import { value } from "./utils/unit";
import { BucketStruct, BucketStructOutput } from "../typechain-types/contracts/FluentProvider";
import { intervalSol } from "../typechain-types/contracts/libraries";

// const ADDR_RAND = ethers.hexlify(ethers.randomBytes(20)).toLowerCase();

describe("FluentHost", function () {
    const GRACE = 60 * 60 * 48;

    // const TOKEN_ADDRESS = ethers.hexlify(ethers.randomBytes(20)).toLowerCase();

    //     // const BUCKET = ethers.hexlify(ethers.randomBytes(32));
    //     // const ADDR_RAND_2 = ethers.hexlify(ethers.randomBytes(20)).toLowerCase();

    let dao: Signer;
    let account: Signer;
    let service: Signer;
    let attacker: Signer;
    let processor: Signer;


    let minReward: bigint;
    let maxReward: bigint;
    //     let hostImpl: FluentHost;
    //     let hostImplAddress: string;

    let token: FluentToken;
    let tokenAddress: string;

    let host: FluentHost;
    let hostAddress: string;
    let hostFactory: FluentHost__factory;

    let providerAddress: string;
    let providerContract: FluentProvider;
    let providerFactory: FluentProvider__factory;

    //     // let provider: prvoider;
    //     let providerImpl: FluentProvider

    //     // let hostFactory: FluentHost__factory
    //     let providerImplFactory: FluentProvider__factory

    //     let providerImplAddress: string

    //     let dao: HardhatEthersSigner;
    //     let account: HardhatEthersSigner;
    //     let attacker: HardhatEthersSigner;
    //     let processor: HardhatEthersSigner;

    //     let daoAddress: string;
    //     let accountAddress: string;
    //     let attackerAddress: string;
    //     let processorAddress: string;


    beforeEach(async function () {
        [dao, service, account, processor, attacker] = await signers.getSigners();

        minReward = unit.value(1, 3)
        maxReward = unit.value(2, 3)
        
        // Provider
        providerFactory = await ethers.getContractFactory("FluentProvider", dao.signer);
        providerContract = await upgrades.deployProxy(providerFactory, [], {
            kind: 'uups',
            redeployImplementation: 'always'
        }).then(x => x.connect(service.signer)) as unknown as FluentProvider;
        providerAddress = await providerContract.getAddress();
        

        // Router
        hostFactory = await ethers.getContractFactory("FluentHost", dao.signer);
        host = await upgrades.deployProxy(hostFactory, [
            GRACE,
            minReward,
            maxReward,
            dao.address,
            providerAddress
        ], {
            kind: 'uups',
            redeployImplementation: 'always'
        }).then(x => x.connect(account.signer)) as unknown as FluentHost;
        hostAddress = await host.getAddress();

        // Token
        let [underlying] = await getUnderlying(dao).then((x) => ([x[0].connect(account.signer), x[1]]) as typeof x);
        [token, tokenAddress] = await getToken(underlying, dao, hostAddress).then((x) => ([x[0].connect(account.signer), x[1]]) as typeof x);


        let value = unit.value(1);

        await underlying.mint(account.address, value);
        await underlying.approve(tokenAddress, value);

        await token.depositFor(account.address, value)
    });

    describe("Initialization", function () {
        it("# 1.1 Should correctly set the provider address", async function () {
            expect(await host.getFunction('provider').staticCall()).to.eq(providerAddress)
        });

        it("# 1.2 Should correctly set the intial values", async function () {
            expect(await host.dao()).to.eq(dao.address)
            expect(await host.gracePeriod()).to.eq(GRACE)
            expect(await host.minReward()).to.eq(minReward)
            expect(await host.maxReward()).to.eq(maxReward)
        });
    })

    describe("Channels", function () {
        let providerId: string
        let channelId: string

        let bucketId: string;
        let bucketData: BucketStruct


        let block: RpcBlockOutput;

        beforeEach(async function () {
            // let group = '0x00000001';
            let interval = 2;

            providerId = ethers.keccak256(abi.encode(["address", "string"], [service.address, provider.validName]))
            channelId = ethers.keccak256(abi.encode(["bytes32", "address"], [providerId, account.address]))
            bucketId = `${ethers.keccak256(abi.encode(["address", "uint64"], [tokenAddress, interval]))}`.slice(0, 10);

            bucketData = {
                token: tokenAddress,
                interval,
                amount: unit.value(10, 6),
            }

            await providerContract.openProvider(provider.validName, [bucketData])

            // let ids = await providerContract.providerBuckets(providerId);
            // console.log(ids, [bucketId])

            // console.log(bucketId);
            // let data = await providerContract.bucketData(providerId, bucketId);
            // console.log(data, bucketData)

            await host.openChannel(providerId, bucketId);

            block = await account.signer.provider.getBlock('latest') as any
        });

        describe("Open", function () {
            it("# 2.1.1 Should correctly set the channel details", async function () {
                const data = await host.getChannel(channelId);

                const current = new Date(parseInt(block.timestamp) * 1e3);
                const expired = new Date(current.setMonth(current.getMonth() + 1)).valueOf() / 1e3;

                expect(data.provider).to.eq(providerId)
                expect(data.account).to.eq(account.address)
                expect(data.expired).to.eq(expired);
                expect(data.bucket).to.eq(bucketId);
            });

            it("# 2.1.2 Should revert if channel is already exists", async function () {
                await expect(host.openChannel(providerId, bucketId))
                    .to.be.revertedWithCustomError(host, "ChannelAlreadyExists").withArgs(channelId);
            });

            it("# 2.1.3 Should revert if provider does not exist", async function () {
                // await expect(host.openChannel(providerId, bucket)).to.be.revertedWithCustomError(host, "ChannelAlreadyExists").withArgs(channelId);
            });

            it("# 2.1.4 Should revert if bucket does not exist", async function () {
                // await expect(host.openChannel(providerId, bucket)).to.be.revertedWithCustomError(host, "ChannelAlreadyExists").withArgs(channelId);
            });
        })

        describe("Close", function () {
            it("# 2.2.1 Should all account to close a channel", async function () {
                await expect(host.closeChannel(channelId)).to.not.be.reverted;
            });

            it("# 2.2.2 Should revert if attacker attempts to close a channel", async function () {
                await expect(host.connect(attacker.signer).closeChannel(channelId))
                    .to.be.revertedWithCustomError(host, 'ChannelUnauthorized').withArgs(attacker.address);
            });

            it("# 2.2.3 Should revert if channel not initialized", async function () {
                const randomId = ethers.randomBytes(32);
                await expect(host.closeChannel(randomId))
                    .to.be.revertedWithCustomError(host, "ChannelDoesNotExist").withArgs(randomId);
            });
        })

        describe("Migrate", function () {
            it("# 2.3.1 Should allow the account to migrate the bucket of a channel", async function () {
                await expect(host.openChannel(providerId, bucketId))
                    .to.be.revertedWithCustomError(host, "ChannelAlreadyExists").withArgs(channelId);
            });
        })

        describe("Process", function () {
            it("# 2.4.1 Should allow the channel to be processed", async function () {
                const current = new Date(parseInt(block.timestamp) * 1e3);
                const expired = new Date(current.setMonth(current.getMonth() + 1)).valueOf() / 1e3;

                await ethers.provider.send("evm_setNextBlockTimestamp", [expired - (GRACE / 2)]);
                await ethers.provider.send("evm_mine", []);


                await expect(host.connect(processor.signer).processChannel(channelId))
                    .to.not.be.reverted;
            });

            // it("# 2.4.2 Should correctly calculate reward", async function () {
            //     const randomId = ethers.randomBytes(32);

            //     await expect(host.connect(processor.signer).processChannel(randomId))
            //         .to.be.revertedWithCustomError(host, "ChannelDoesNotExist").withArgs(randomId);
            // });

            it("# 2.4.2 Should revert if the channel does not exists", async function () {
                const randomId = ethers.randomBytes(32);

                await expect(host.connect(processor.signer).processChannel(randomId))
                    .to.be.revertedWithCustomError(host, "ChannelDoesNotExist").withArgs(randomId);
            });

            it("# 2.4.3 Should revert if the channel is locked", async function () {
                await expect(host.connect(processor.signer).processChannel(channelId))
                    .to.be.revertedWithCustomError(host, "ChannelLocked").withArgs(channelId);
            });
        })

        // it("# 2.4 Should revert if channel not initialized", async function () {
        //     const randomId = ethers.randomBytes(32);
        //     await expect(host.channel(randomId)).to.be.revertedWithCustomError(host, "ChannelDoesNotExist").withArgs(randomId);
        // });

        // it("# 2.5 Should revert if channel already initialized", async function () {
        //     await expect(host.openChannel(providerId, bucket)).to.be.revertedWithCustomError(host, "ChannelAlreadyExists").withArgs(channelId);
        // });

        // it("# 1.1 Should revert if channel already initialized", async function () {
        // });
    })

    //     describe("Channels", function () {
    //         let channel: string;
    //         let bucket: string;
    //         let started: number;

    //         async function openChannel(signer: HardhatEthersSigner = account) {
    //             return await host.connect(signer).openChannel(processorAddress, bucket);
    //         }

    //         async function closeChannel(signer: HardhatEthersSigner = account) {
    //             await host.connect(signer).closeChannel(channel);
    //         }

    //         async function processChannel(signer: HardhatEthersSigner = processor) {
    //             await host.connect(signer).processChannel(channel, signer);
    //         }

    //         beforeEach(async () => {
    //             bucket = ethers.hexlify(ethers.randomBytes(4));
    //             channel = ethers.keccak256(ethers.AbiCoder.defaultAbiCoder().encode([
    //                 'address',
    //                 'address'
    //             ], [
    //                 processorAddress,
    //                 accountAddress
    //             ]));

    //             const tx = await openChannel()
    //             const receipt = await tx.wait();

    //             started = (await ethers.provider.getBlock(receipt!.blockNumber))!.timestamp
    //         });

    //         describe('Opens', () => {
    //             it("# 2.1.1 Should correctly open a new channel", async function () {
    //                 const data = await host.channelData(channel);

    //                 expect(data.bucket).to.eq(bucket);
    //                 expect(data.started).to.eq(started);
    //                 expect(data.expired).to.eq(started + 60);
    //                 expect(data.account).to.eq(accountAddress);
    //                 expect(data.account).to.eq(accountAddress);
    //             });

    //             it("# 2.1.2 Should revert if the channel already exists", async function () {
    //                 await expect(openChannel()).to.be
    //                     .revertedWithCustomError(host, 'ChannelAlreadyExists')
    //                     .withArgs(channel);
    //             });
    //         })

    //         describe('Closes', () => {
    //             beforeEach(async () => {
    //                 await closeChannel()
    //             })

    //             it("# 2.2.1 Should correctly close channel", async function () {
    //                 const data = await host.channelData(channel);

    //                 expect(data.expired).to.eq(0n);
    //                 expect(data.started).to.eq(0n);
    //                 expect(data.bucket).to.eq(ethers.ZeroHash.slice(0, 10));
    //                 expect(data.account).to.eq(ethers.ZeroAddress);
    //                 expect(data.account).to.eq(ethers.ZeroAddress);
    //             });

    //             it("# 2.2.2 Should revert if the channel does not exist", async function () {
    //                 await expect(closeChannel()).to.be
    //                     .revertedWithCustomError(host, 'ChannelDoesNotExist')
    //                     .withArgs(channel);
    //             });

    //             it("# 2.2.3 Should revert if account is not channel owner", async function () {
    //                 await openChannel()

    //                 await expect(closeChannel(attacker)).to.be
    //                     .revertedWithCustomError(host, 'UnauthorizedAccount')
    //                     .withArgs(attackerAddress);
    //             });
    //         })

    //         describe('Transactions', () => {
    //             it("# 2.3.1 Should allow processor to process a channel", async function () {
    //             });

    //             it("# 2.3.2 Should revert if the channel does not exist", async function () {
    //             });
    //         })

    //         describe('Liquidations', () => {
    //             it("# 2.3.1 Should allow user to close their channel", async function () {
    //             });

    //             it("# 2.3.2 Should revert if the channel does not exist", async function () {
    //             });
    //         })



    //         // describe('Close', () => {
    //         //     it("# 2.2 Should allow user to close their channel", async function () {
    //         //         expect(await host.closeChannel(channel)).to.emit(host, "ChannelClosed").withArgs(channel);
    //         //     });

    //         //     this.beforeEach(async () => {
    //         //         await host.closeChannel(channel)
    //         //     })

    //         //     it("# 2.3 Should revert if channel does not exist", async function () {
    //         //         expect(await host.closeChannel(channel)).to
    //         //             .revertedWithCustomError(host, 'ChannelDoesNotExist')
    //         //             .withArgs(channel);
    //         //     });
    //         // });

    //     })

    //     describe("Transactions", function () {
    //         // it("# 1.1 Should allow user to open a channel", async function () {
    //         // });
    //     });

    //     describe("Liquidations", function () {
    //         // it("# 1.1 Should allow user to open a channel", async function () {
    //         // });
    //     });
})