// This script reads the total supply field
// of the FiatToken smart contract

import FiatToken from 0x{{.FiatToken}}

pub fun main(): UFix64 {

    let supply = FiatToken.totalSupply

    log(supply)

    return supply
}
