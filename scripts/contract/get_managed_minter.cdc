// This gets the managed Minter of a MinterController
// If non is set by the MasterMinter, nil will return

import "FiatToken"

access(all) fun main(uuid: UInt64): UInt64? {
    return FiatToken.getManagedMinter(resourceId: uuid)
}
