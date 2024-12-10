// import { ethers } from "hardhat";
// import { Signer } from "./types";
// import { BucketStruct } from "../typechain-types/contracts/FluentProvider";

export * as provider from "./provider";
export * as signers from './signers';
export { abi } from './abi';

// const utils = {
//     provider: {
//         validName: "StackExchange",
//         invalidName: "Harmonic Convergence Data Exchange Hub",
//         buckets: {
//             generate: (tokens: string[]): BucketStruct[] => {
//                 return tokens.map(token => ({
//                     token,
//                     freeTrial: 2n,
//                     interval: 32n,
//                     amount: 32n
//                 }))
//             }
//         }
//         // buckets: [{
//         //     token: ,
//         //     freeTrial: 2n,
//         //     interval: 32n,
//         //     amount: 32n
//         // }] as BucketStruct[]
//     },
//     abi: ethers.AbiCoder.defaultAbiCoder(),

// }

// export async function getSigners(): Promise<Signer[]> {
//     const base = await ethers.getSigners();
//     const futures = base.map(async x => ({
//         signer: x,
//         address: await x.getAddress()
//     }))

//     return Promise.all(futures)
// }

// export default utils;