import { HardhatUserConfig } from "hardhat/config"
import "@nomicfoundation/hardhat-toolbox"
import "dotenv/config"

const RPC_MORPH_URL = process.env.RPC_MORPH_URL!
const DEPLOYER_PK = process.env.DEPLOYER_PK!
const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY!

const config: HardhatUserConfig = {
  solidity: "0.8.24",
  etherscan: {
    enabled: true,
    apiKey: ETHERSCAN_API_KEY,
    customChains: [
      {
        chainId: 2810,
        // holesky morph testnet
        network: "morphTestnet",
        urls: {
          apiURL: "https://explorer-api-holesky.morphl2.io/api",
          browserURL: "https://explorer-holesky.morphl2.io",
        },
      },
    ],
  },

  networks: {
    hardhat: {
      forking: {
        url: RPC_MORPH_URL,
        enabled: true,
      },
    },
    morphTestnet: {
      url: RPC_MORPH_URL,
      accounts: [DEPLOYER_PK],
    },
  },
}

export default config
