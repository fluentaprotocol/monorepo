import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";

export interface Signer {
    signer: HardhatEthersSigner,
    address: string
}

export enum Interval {
    Daily = 0,
    Weekly = 1,
    Monthly = 2,
    Quaterly = 3,
    Annually = 4
};
