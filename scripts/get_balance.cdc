// This script reads the balance field of an account's USDC Balance

import FungibleToken from 0x{{.FungibleToken}}
import USDC from 0x{{.USDCToken}}

pub fun main(account: Address): UFix64 {
    let acct = getAccount(account)
    let vaultRef = acct.getCapability(/public/UsdcBalance)
        .borrow<&USDC.Vault{FungibleToken.Balance}>()
        ?? panic("Could not borrow Balance reference to the Vault")

    return vaultRef.balance
}
