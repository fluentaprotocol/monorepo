import { ethers } from "hardhat";
import { BucketStruct } from "../../typechain-types/contracts/FluentProvider";
import { Interval } from "../types";
import { unit } from ".";

export const validName = "StackExchange";
export const invalidName = "Harmonic Convergence Data Exchange Hub";
// export const buckets: BucketStruct[] = [{
//     token: ethers.hexlify(ethers.randomBytes(20)).toLowerCase(),
//     interval: 1n,
//     amount: 32n,
// }]

export function getBucket(token: string, interval: Interval, amount = unit.value(10, 6), group: string = '0x00000000') {
    return {
        token,
        interval,
        group,
        amount,
    }
}