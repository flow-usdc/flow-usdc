// This script reads the total supply field
// of the USDC smart contract

import USDC from 0x{{.UsdcToken}}

pub fun main(): UFix64 {

    let supply = USDC.totalSupply

    log(supply)

    return supply
}
