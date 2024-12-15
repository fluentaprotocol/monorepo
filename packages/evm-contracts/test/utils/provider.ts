import { ethers } from "hardhat";
import { Interval } from "../types";
import { unit } from ".";

export const validName = "StackExchange";
export const invalidName = "Harmonic Convergence Data Exchange Hub";
// export const buckets: BucketStruct[] = [{
//     token: ethers.hexlify(ethers.randomBytes(20)).toLowerCase(),
//     interval: 1n,
//     amount: 32n,
// }]

export function getEndpoint(token: string, interval: Interval, amount = unit.value(10, 6), bucket: string = '0x00000000') {
    return {
        token,
        interval,
        bucket,
        amount,
    }
}