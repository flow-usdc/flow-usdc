// This script reads the allowance field set in a vault for another resource 

import FungibleToken from 0x{{.FungibleToken}}
import FiatToken from 0x{{.FiatToken}}

pub fun main(fromAcct: Address, toResourceId: UInt64): UFix64 {
    let acct = getAccount(fromAcct)
    let vaultRef = acct.getCapability(FiatToken.VaultAllowancePubPath)
        .borrow<&FiatToken.Vault{FiatToken.Allowance}>()
        ?? panic("Could not borrow Allowance reference to the Vault")
    return vaultRef.allowance(resourceId: toResourceId)!
}
