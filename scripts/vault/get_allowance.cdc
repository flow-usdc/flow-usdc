// This script reads the allowance field set in a vault for another resource 

import FungibleToken from 0x{{.FungibleToken}}
import FiatToken from 0x{{.FiatToken}}

access(all) fun main(fromAcct: Address, toResourceId: UInt64): UFix64 {
    let acct = getAccount(fromAcct)
    let vaultRef = acct.capabilities.get<&{FiatToken.Allowance}>(FiatToken.VaultAllowancePubPath)
        .borrow()
        ?? panic("Could not borrow Allowance reference to the Vault")
    return vaultRef.allowance(resourceId: toResourceId)!
}
