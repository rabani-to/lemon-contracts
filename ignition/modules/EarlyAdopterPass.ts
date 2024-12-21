import hre from "hardhat"
import { buildModule } from "@nomicfoundation/hardhat-ignition/modules"
import { zeroAddress } from "viem"

// hh ignition deploy --network morphTestnet ignition/modules/EarlyAdopterPass.ts --verify

const EarlyAdopterPassModule = buildModule("EarlyAdopterPassModule", (m) => {
  const maxSupply = {
    morphTestnet: BigInt(817),
    morphMainnet: BigInt(256),
    maticMainnet: BigInt(420),
    baseMainnet: BigInt(420),
    ethMainnet: BigInt(420),
  }[hre.network.name as "morphTestnet"]

  const isMorphTestnet = hre.network.name === "morphTestnet"

  const contract = m.contract("EarlyAdopterPass", [
    maxSupply ?? BigInt(0),
    isMorphTestnet ? "0x4ce2610123BFF1B64ACAaCD3C9FD95B56B56Cd0F" : zeroAddress,
    // MOPRH: 817
    // REST: 420 (ETH, Polygon, Base)
    // All chains: 817 + (420 * 3) = 2077
  ])
  return { contract }
})

export default EarlyAdopterPassModule
