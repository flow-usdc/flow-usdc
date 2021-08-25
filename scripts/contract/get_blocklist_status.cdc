// This gets the blocklist status of a resource
// If is it blocklisted, the block it happen will be returned
// If it is not blocklisted, nil will return

import FiatToken from 0x{{.FiatToken}}

pub fun main(uuid: UInt64): UInt64? {
    return FiatToken.getBlocklist(resourceId: uuid)
}
