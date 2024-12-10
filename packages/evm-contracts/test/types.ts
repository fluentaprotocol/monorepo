import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";

export interface Signer {
    signer: HardhatEthersSigner,
    address: string
}