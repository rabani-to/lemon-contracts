import { buildModule } from "@nomicfoundation/hardhat-ignition/modules"
// hh ignition deploy --network morphTestnet ignition/modules/SimpleDonationModule.ts --verify --deployment-id "v0_0_1"

const SimpleDonationModule = buildModule("SimpleDonationModule", (m) => {
  const contract = m.contract("SimpleDonationModule")

  return { contract }
})

export default SimpleDonationModule
