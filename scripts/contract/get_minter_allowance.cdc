// This gets the Minter's allowance set by a MinterController
// If non is set, this will return error

import "FiatToken"

access(all) fun main(uuid: UInt64): UFix64 {
    return FiatToken.getMinterAllowance(resourceId: uuid)!
}
