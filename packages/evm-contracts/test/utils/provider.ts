import { ethers } from "hardhat";
import { Interval } from "../types";
import { abi, unit } from ".";
import { BucketStruct, EndpointStruct } from "../../typechain-types/contracts/FluentProvider";

export const validName = "StackExchange";
export const invalidName = "Harmonic Convergence Data Exchange Hub";
// export const buckets: BucketStruct[] = [{
//     token: ethers.hexlify(ethers.randomBytes(20)).toLowerCase(),
//     interval: 1n,
//     amount: 32n,
// }]

export function getBucket(interval: Interval, name = "FluentaSubs"): [BucketStruct, string] {
    let tag = `${ethers.keccak256(abi.encode(["string", "uint"], [name, interval])).slice(0, 10)}`
    
    let data: BucketStruct = {
        interval,
        name
    }
    
    return [data, tag]
}

export function getEndpoint(token: string, bucket: string, amount = unit.value(10, 6)): [EndpointStruct, string] {
    let tag = `${ethers.keccak256(abi.encode(["address", "bytes4"], [token, bucket])).slice(0, 10)}`
    let data: EndpointStruct = {
        token,
        amount,
        bucket
    }

    return [data, tag]
}