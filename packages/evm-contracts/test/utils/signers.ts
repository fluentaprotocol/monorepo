import { ethers } from "hardhat";
import { Signer } from "../types";
// import { Signer } from "./types";

export async function getSigners(): Promise<Signer[]> {
    const base: any[] = await ethers.getSigners();
    const futures = base.map(async x => ({
        signer: x,
        address: await x.getAddress()
    }))

    return Promise.all(futures)
}
