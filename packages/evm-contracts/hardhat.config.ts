import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import '@openzeppelin/hardhat-upgrades';
import "hardhat-gas-reporter"

const config: HardhatUserConfig = {
  solidity: {
    compilers: [
      { version: "0.8.27" },
    ]
  },
  gasReporter: {
    L1: 'ethereum',
    L2: 'arbitrum',
    darkMode: true,
    includeIntrinsicGas: true,
    excludeContracts: [
      'MockERC20'
    ]
  }
};

export default config;
