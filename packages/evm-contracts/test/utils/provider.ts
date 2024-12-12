import { ethers } from "hardhat";
import { BucketStruct } from "../../typechain-types/contracts/FluentProvider";

export const validName = "StackExchange";
export const invalidName = "Harmonic Convergence Data Exchange Hub";
export const buckets: BucketStruct[] = [{
    token: ethers.hexlify(ethers.randomBytes(20)).toLowerCase(),
    interval: 1n,
    amount: 32n,
}]