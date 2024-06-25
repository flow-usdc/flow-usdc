// Gets the pause state of the contract

import "FiatToken"

access(all) fun main(): Bool {
    return FiatToken.paused
}
