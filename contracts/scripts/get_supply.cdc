// This script reads the total supply field
// of the ExampleToken smart contract

import ExampleToken from 0x01cf0e2f2f715450

pub fun main(): UFix64 {

    let supply = ExampleToken.totalSupply

    log(supply)

    return supply
}
