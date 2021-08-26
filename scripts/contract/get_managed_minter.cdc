// This gets the managed Minter of a MinterController
// If non is set by the MasterMinter, nil will return

import FiatToken from 0x{{.FiatToken}}

pub fun main(uuid: UInt64): UInt64? {
    return FiatToken.getManagedMinter(resourceId: uuid)
}
