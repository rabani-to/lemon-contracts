import { buildModule } from "@nomicfoundation/hardhat-ignition/modules"
import { parseUnits } from "viem"
// hh ignition deploy --network morphTestnet ignition/modules/mocks/MockLemonToken.ts --verify

const MockLemonToken = buildModule("MockLemonToken", (m) => {
  let decimals = 6
  const balance = "1000000"

  const token_6 = m.contract(
    "MockLemonToken",
    [decimals, parseUnits(balance, decimals)],
    {
      id: `decimals_${decimals}`,
    }
  )

  decimals = 18
  const token_18 = m.contract(
    "MockLemonToken",
    [decimals, parseUnits(balance, decimals)],
    {
      id: `decimals_${decimals}`,
    }
  )

  return { token_6, token_18 }
})

export default MockLemonToken
