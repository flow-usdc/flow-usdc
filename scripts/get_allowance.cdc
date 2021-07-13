// This script reads the allowance field set in a vault for another resource 

import FungibleToken from 0x{{.FungibleToken}}
import USDC from 0x{{.USDCToken}}
import USDCInterface from 0x{{.USDCInterface}}

pub fun main(fromAcct: Address, toResourceId: UInt64): UFix64 {
    let acct = getAccount(fromAcct)
    let vaultRef = acct.getCapability(/public/UsdcVaultAllowance)
        .borrow<&USDC.Vault{USDCInterface.Allowance}>()
        ?? panic("Could not borrow Allowance reference to the Vault")
    return vaultRef.allowance(resourceId: toResourceId)!
}
