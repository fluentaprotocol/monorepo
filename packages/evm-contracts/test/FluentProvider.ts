// import { expect } from "chai";
// import { ethers, upgrades } from "hardhat";
// import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
// import { FluentProvider, FluentProvider__factory } from "../typechain-types";

// describe("FluentProvider", function () {
//   //     const BYTES_RAND = ethers.hexlify(ethers.randomBytes(32));
//   const HOST_ADDRESS = ethers.hexlify(ethers.randomBytes(20)).toLowerCase();
//   const TOKEN_ADDRESS = ethers.hexlify(ethers.randomBytes(20)).toLowerCase();

//   let validator: HardhatEthersSigner;
//   let account: HardhatEthersSigner;
//   let attacker: HardhatEthersSigner;

//   let factory: FluentProvider__factory;
//   let collector: FluentProvider;

//   let validatorAddress: string;
//   let accountAddress: string;
//   let attackerAddress: string;

//   beforeEach(async function () {
//     [validator, account, attacker] = await ethers.getSigners();

//     validatorAddress = await validator.getAddress();
//     accountAddress = await account.getAddress();
//     attackerAddress = await attacker.getAddress();

//     factory = await ethers.getContractFactory("FluentProvider", validator);
//     collector = (await upgrades
//       .deployProxy(factory, [accountAddress, HOST_ADDRESS], {
//         kind: "uups",
//         redeployImplementation: "always",
//       })
//       .then((x) => x.connect(account))) as unknown as FluentProvider;
//   });

//   describe("Initialization", function () {
//     it("# 1.1 Should set the correct host address", async function () {
//       let host = await collector.host();
//       expect(host.toLowerCase()).to.eq(HOST_ADDRESS);
//     });

//     it("# 1.2 Should set the correct owner address", async function () {
//       expect(await collector.owner()).to.eq(accountAddress);
//     });

//     // it("# 1.3 Should set the correct factory address", async function () {
//     //     let host = await collector.factory();
//     //     expect(host.toLowerCase()).to.eq(ADDR_RAND_2)
//     // });
//   });

//   describe("Tiers", function () {
//     it("# 2.1 Should allow owner to create a tier", async function () {
//       await collector.createTier(TOKEN_ADDRESS, 100n);
//       //   expect(host.toLowerCase()).to.eq(HOST_ADDRESS);
//     });

//     it("# 2.1 Should revert if non-owner tries to create a tier", async function () {
//       await expect(
//         collector.connect(attacker).createTier(TOKEN_ADDRESS, 1n)
//       ).to.revertedWith("UnauthorizedOwner");
//       //   expect(host.toLowerCase()).to.eq(HOST_ADDRESS);
//     });

//     // it("# 2.2 Should set the correct owner address", async function () {
//     //   expect(await collector.owner()).to.eq(accountAddress);
//     // });

//     // it("# 1.3 Should set the correct factory address", async function () {
//     //     let host = await collector.factory();
//     //     expect(host.toLowerCase()).to.eq(ADDR_RAND_2)
//     // });
//   });
// });
