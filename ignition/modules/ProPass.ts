import { buildModule } from "@nomicfoundation/hardhat-ignition/modules"

// hh ignition deploy --network morphTestnet ignition/modules/ProPass.ts --verify

const DEV_ADDRESS = "0xB6594a5EdDA3E0D910Fb57db7a86350A9821327a"
const ProPass = buildModule("ProPass", (m) => {
  const contract = m.contract("ProPass", [DEV_ADDRESS])
  return { contract }
})

export default ProPass
