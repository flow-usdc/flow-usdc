// Gets the pause state of the contract

import FiatToken from 0x{{.FiatToken}}

pub fun main(): Bool {
    return FiatToken.paused
}
