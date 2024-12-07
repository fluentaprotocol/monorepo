// import { expect } from "chai";
// import { ethers, upgrades } from "hardhat";
// import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
// import { FluentProvider__factory, FluentProvider, FluentHost__factory, FluentHost, Address } from "../typechain-types";
// import { deployHost, deployHostImplementation } from "./utils/deploy";

// const ADDR_RAND = ethers.hexlify(ethers.randomBytes(20)).toLowerCase();

// describe("FluentHost", function () {
//     // const BUCKET = ethers.hexlify(ethers.randomBytes(32));
//     // const ADDR_RAND_2 = ethers.hexlify(ethers.randomBytes(20)).toLowerCase();

//     let hostImpl: FluentHost;
//     let hostImplAddress: string;
    
//     let host: FluentHost;
//     let hostAddress: string;
    
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


//     beforeEach(async function () {
//         [dao, account, processor, attacker] = await ethers.getSigners();

//         daoAddress = await dao.getAddress();
//         accountAddress = await account.getAddress();
//         attackerAddress = await attacker.getAddress();
//         processorAddress = await processor.getAddress();

//         // [hostImpl, hostImplAddress] = await deployHostImplementation(dao);
//         [host, hostAddress] = await deployHost(dao);

//         // providerImpl = await deployProviderImplementation();
//         // providerImpl = await upgrades.deployProxy(providerImplFactory, [], {
//         //     kind: 'uups',
//         //     redeployImplementation: 'always'
//         // }).then(x => x.connect(account)) as unknown as FluentProvider;


//         // providerImplAddress = await providerImpl.getAddress();

//     });

//     describe("Initialization", function () {
//         // it("# 1.1 ", async function () {
//         // });
//     })

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
// })