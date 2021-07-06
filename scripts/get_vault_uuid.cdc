// This script reads the balance field of an account's USDC Balance
import USDC from 0x{{.USDCToken}}
import USDCInterface from 0x{{.USDCInterface}}


pub fun main(account: Address): UInt64 {
    let acct = getAccount(account)
    let vaultRef = acct.getCapability(/public/UsdcVaultUUID)
        .borrow<&USDC.Vault{USDCInterface.VaultUUID}>()
        ?? panic("Could not borrow Get UUID reference to the Vault")

    return vaultRef.UUID()
}
