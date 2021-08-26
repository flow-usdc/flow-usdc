// This gets the Minter's allowance set by a MinterController
// If non is set, this will return error

import FiatToken from 0x{{.FiatToken}}

pub fun main(uuid: UInt64): UFix64 {
    return FiatToken.getMinterAllowance(resourceId: uuid)!
}
