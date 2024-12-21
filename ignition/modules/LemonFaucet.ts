import hre from "hardhat"
import { buildModule } from "@nomicfoundation/hardhat-ignition/modules"

// hh ignition deploy --network morphTestnet ignition/modules/LemonFaucet.ts --verify

const LemonFaucet = buildModule("LemonFaucet", (m) => {
  const FEE_TOKEN_ADDRESS = {
    morphTestnet: "0x26DFDd3C39179D246B6Ed5c0b438eBd14767D551",
    // Lemon Mock Token
  }[hre.network.name as "morphTestnet"]

  const contract = m.contract("LemonFaucet", [FEE_TOKEN_ADDRESS])

  return { contract }
})

export default LemonFaucet
