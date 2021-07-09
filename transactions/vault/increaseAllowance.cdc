import USDC from 0x{{.USDCToken}}
import USDCInterface from 0x{{.USDCInterface}}

transaction(toResourceId: UInt64, delta: UFix64) {

    prepare (fromAcct: AuthAccount) {
        // Get a reference to the signer's stored vault
        let vaultRef = fromAcct.borrow<&USDC.Vault>(from: /storage/UsdcVault)
            ?? panic("Could not borrow reference to the owner's Vault!")

        vaultRef.increaseAllowance(resourceId: toResourceId, increment: delta)
    }
}
