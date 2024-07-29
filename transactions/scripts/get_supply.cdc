// This script reads the total supply field
// of the FiatToken smart contract

import "FiatToken"

access(all) fun main(): UFix64 {
    return FiatToken.totalSupply
}
