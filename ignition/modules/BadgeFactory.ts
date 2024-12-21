import { buildModule } from "@nomicfoundation/hardhat-ignition/modules"

// hh ignition deploy --network arbMainnet ignition/modules/BadgeFactory.ts --verify
// hh verify --network arbMainnet NFT_ADDRESS FACTORY ...constructor_args

const DEV_ADDRESS = "0xB6594a5EdDA3E0D910Fb57db7a86350A9821327a"
const BadgeFactory = buildModule("BadgeFactory", (m) => {
  const contract = m.contract("BadgeFactory", [DEV_ADDRESS])

  return { contract }
})

export default BadgeFactory
