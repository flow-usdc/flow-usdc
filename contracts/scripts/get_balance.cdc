// This script reads the balance field of an account's FlowToken Balance

import FungibleToken from 0xee82856bf20e2aa6
import ExampleToken from 0x01cf0e2f2f715450

pub fun main(account: Address): UFix64 {
    let acct = getAccount(account)
    let vaultRef = acct.getCapability(/public/exampleTokenBalance)
        .borrow<&ExampleToken.Vault{FungibleToken.Balance}>()
        ?? panic("Could not borrow Balance reference to the Vault")

    return vaultRef.balance
}
