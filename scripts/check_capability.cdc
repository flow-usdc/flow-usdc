// This script checks if the provided identifier is in the address public capability path 

import FungibleToken from 0x{{.FungibleToken}}
import USDC from 0x{{.USDCToken}}

pub fun main(account: Address, capPath: PublicPath, capa: Capability): Bool {
    let acct = getAccount(account)
    return acct.getCapability<capa>(capPath).check()
}
