// This gets the current version of the contract

import "FiatToken"

access(all) fun main(): String {
    return FiatToken.version
}
