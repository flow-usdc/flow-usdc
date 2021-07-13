// This script reads the balance field of an account's FiatToken Balance

import FungibleToken from 0x{{.FungibleToken}}
import FiatToken from 0x{{.FiatToken}}

pub fun main(account: Address): UFix64 {
    let acct = getAccount(account)
    let vaultRef = acct.getCapability(FiatToken.VaultBalancePubPath)
        .borrow<&FiatToken.Vault{FungibleToken.Balance}>()
        ?? panic("Could not borrow Balance reference to the Vault")

    return vaultRef.balance
}
