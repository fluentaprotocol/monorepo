import { ethers } from "hardhat"

export function value(amount: number, decimals = 18) {
    return ethers.parseUnits(`${amount}`, decimals)
}

