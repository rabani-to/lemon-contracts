import { buildModule } from "@nomicfoundation/hardhat-ignition/modules"

// hh ignition deploy --network hardhat ignition/modules/CartBitRecords.ts

const SimpleDonationModule = buildModule("SimpleDonationModule", (m) => {
  const contract = m.contract("SimpleDonationModule")

  return { contract }
})

export default SimpleDonationModule
