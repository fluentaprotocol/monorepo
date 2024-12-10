// import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
// import { ethers, upgrades } from "hardhat";
// import {
//   FluentProvider,
//   UUPSProxy,
// } from "../../typechain-types";

// export async function deployHostImplementation(
//   dao: HardhatEthersSigner
// ): Promise<[FluentHost, string]> {
//   let host = await deploy<FluentHost>("FluentHost", dao);
//   let address = await host.getAddress();

//   return [host, address];
// }

// export async function deployHostProxy(
//   dao: HardhatEthersSigner,
//   implementation?: string
// ): Promise<[FluentHost, string]> {
//   let proxy = await deploy<UUPSProxy>("UUPSProxy", dao);
  
//   let impl: string = implementation ?? (await deployHostImplementation(dao).then(x => x[1]));
//   await proxy.initializeProxy(impl)
  
//   let address = await proxy.getAddress();
//   let host = await ethers.getContractAt("FluentHost", address) as FluentHost;

//   return [host, address];
// }

// export async function deployHost(
//   dao: HardhatEthersSigner
// ): Promise<[FluentHost, string]> {
//   ethers.deployContract("UUPSProxy")
//   let host = await deployUpgradeable<FluentHost>("FluentHost", dao);
//   let address = await host.getAddress();

//   return [host, address];
// }

// // export async function deployProvider(
// //   factory: FluentProviderFactory
// // ): Promise<[FluentHost, string]> {
// //   factory.openCollector()
// //   // let host = await deployUpgradeable<FluentHost>("FluentHost", dao);
// //   // let address = await host.getAddress();

// //   return [host, address];
// // }



// // export async function deployProviderImplementation(
// //   dao: HardhatEthersSigner
// // ): Promise<[FluentProvider, string]> {
// //   let implementation = await deploy<FluentProvider>("FluentProvider", dao);
// //   let address = await implementation.getAddress();

// //   return [implementation, address];
// // }

// // export async function deployProviderFactory(
// //   dao: HardhatEthersSigner,
// //   implementation: string,
// //   host: string
// // ): Promise<[FluentProviderFactory, string]> {
// //   let factory = await deployUpgradeable<FluentProviderFactory>(
// //     "FluentProviderFactory",
// //     dao,
// //     [host, implementation]
// //   );
// //   let factoryAddress = await factory.getAddress();

// //   return [factory, factoryAddress];
// // }

// async function deployUpgradeable<T>(
//   name: string,
//   signer: HardhatEthersSigner,
//   args: any[] = []
// ) {
//   let factory = await ethers.getContractFactory(name, signer);
//   let result = (await upgrades.deployProxy(factory, args, {
//     kind: "uups",
//     redeployImplementation: "always",
//   })) as unknown as T;

//   return result;
// }

// async function deploy<T>(
//   name: string,
//   signer: HardhatEthersSigner,
//   args: any[] = []
// ) {
//   let factory = await ethers.getContractFactory(name, signer);
//   let result = await factory.deploy(args);

//   return result as T;
// }
