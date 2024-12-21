import type { HardhatUserConfig } from "hardhat/config"
import "@nomicfoundation/hardhat-toolbox"
import "dotenv/config"

const argv = require("yargs/yargs")(process.argv.slice(2)).parse()
const NETWORK = argv.network as string

const ETHERSCAN_ETHEREUM_KEY = process.env.ETHERSCAN_ETHEREUM_KEY!
const ETHERSCAN_BASE_KEY = process.env.ETHERSCAN_BASE_KEY!
const ETHERSCAN_MATIC_KEY = process.env.ETHERSCAN_MATIC_KEY!
const ETHERSCAN_ARB_KEY = process.env.ETHERSCAN_ARB_KEY!
const DEPLOYER_PK = process.env.DEPLOYER_PK!

const ETHERSCAN_API_KEY =
  {
    baseMainnet: ETHERSCAN_BASE_KEY,
    maticMainnet: ETHERSCAN_MATIC_KEY,
    arbMainnet: ETHERSCAN_ARB_KEY,
  }[NETWORK] || ETHERSCAN_ETHEREUM_KEY // default to ethereum

console.debug("Network:", NETWORK || "N/A")

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.24",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
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
      {
        chainId: 2818,
        network: "morphMainnet",
        urls: {
          apiURL: "https://explorer-api.morphl2.io/api",
          browserURL: "https://explorer.morphl2.io",
        },
      },
    ],
  },
  networks: {
    morphTestnet: {
      url: "https://rpc-quicknode-holesky.morphl2.io",
      accounts: [DEPLOYER_PK],
    },
    morphMainnet: {
      url: "https://rpc-quicknode.morphl2.io",
      accounts: [DEPLOYER_PK],
    },
    arbMainnet: {
      url: "https://arb1.arbitrum.io/rpc",
      accounts: [DEPLOYER_PK],
    },
    maticMainnet: {
      url: "https://polygon-bor-rpc.publicnode.com",
      accounts: [DEPLOYER_PK],
    },
    baseMainnet: {
      url: "https://base-rpc.publicnode.com",
      accounts: [DEPLOYER_PK],
    },
    ethMainnet: {
      url: "https://eth.llamarpc.com",
      accounts: [DEPLOYER_PK],
    },
    ethSepolia: {
      url: "https://ethereum-sepolia-rpc.publicnode.com",
      accounts: [DEPLOYER_PK],
    },
    opMainnet: {
      url: "https://1rpc.io/op",
      accounts: [DEPLOYER_PK],
    },
  },
}

export default config
