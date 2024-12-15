import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "@openzeppelin/hardhat-upgrades";
import "hardhat-gas-reporter";

const config: HardhatUserConfig = {
  solidity: {
    compilers: [
      {
        version: "0.8.27",
        settings: {
          evmVersion: 'shanghai',
          viaIR: true,
        },
      },
      {
        version: "0.8.4",
        settings: {
          evmVersion: 'shanghai',
        },
      },
    ],
  },
  gasReporter: {
    L1: "ethereum",
    L2: 'optimism',
    gasPrice: 0.0000702,
    baseFee: 10.6,
    blobBaseFee: 0,
    currency: "USD",
    token: "OP",
    tokenPrice: "2.5" as any,
    includeIntrinsicGas: true,
    excludeContracts: ["MockERC20"],
  },
};

export default config;
