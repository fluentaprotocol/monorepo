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
          viaIR: true,
        },
      },
      {
        version: "0.8.4",
        settings: {
          viaIR: true,
          optimizer: {
            enabled: true,
            details: {
              yulDetails: {
                optimizerSteps: "u",
              },
            },
          },
        },
      },
    ],
  },
  gasReporter: {
    L1: "ethereum",
    gasPrice: 21,
    currency: "USD",
    token: "ETH",
    tokenPrice: "4041.81" as any,
    includeIntrinsicGas: true,
    excludeContracts: ["MockERC20"],
  },
};

export default config;
