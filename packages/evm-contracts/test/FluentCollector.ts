// import { expect } from "chai";
// import { ethers, upgrades } from "hardhat";
// import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
// import { FluentProvider__factory, FluentProvider } from "../../typechain-types";


// describe("FluentCollector", function () {
//     const BYTES_RAND = ethers.hexlify(ethers.randomBytes(32));
//     const ADDR_RAND = ethers.hexlify(ethers.randomBytes(20)).toLowerCase();
//     const ADDR_RAND_2 = ethers.hexlify(ethers.randomBytes(20)).toLowerCase();

//     let validator: HardhatEthersSigner;
//     let account: HardhatEthersSigner;
//     let attacker: HardhatEthersSigner;

//     let factory: FluentProvider__factory
//     let collector: FluentProvider;

//     let validatorAddress: string;
//     let accountAddress: string;
//     let attackerAddress: string;

//     beforeEach(async function () {
//         [validator, account, attacker] = await ethers.getSigners();

//         validatorAddress = await validator.getAddress();
//         accountAddress = await account.getAddress();
//         attackerAddress = await attacker.getAddress();

//         factory = await ethers.getContractFactory("FluentProvider", validator);
//         collector = await upgrades.deployProxy(factory, [accountAddress, ADDR_RAND_2, ADDR_RAND], {
//             kind: 'uups',
//             redeployImplementation: 'always'
//         }).then(x => x.connect(account)) as unknown as FluentProvider;
//     });

//     describe("Initialization", function () {
//         it("# 1.1 Should set the correct host address", async function () {
//             let host = await collector.host();
//             expect(host.toLowerCase()).to.eq(ADDR_RAND)
//         });

//         it("# 1.2 Should set the correct owner address", async function () {
//             expect(await collector.owner()).to.eq(accountAddress)
//         });

//         // it("# 1.3 Should set the correct factory address", async function () {
//         //     let host = await collector.factory();
//         //     expect(host.toLowerCase()).to.eq(ADDR_RAND_2)
//         // });
//     });
// })