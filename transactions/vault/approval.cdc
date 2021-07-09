import USDC from 0x{{.USDCToken}}
import USDCInterface from 0x{{.USDCInterface}}

transaction(toResourceId: UInt64, amount: UFix64) {

    prepare (fromAcct: AuthAccount) {
        // Get a reference to the signer's stored vault
        let vaultRef = fromAcct.borrow<&USDC.Vault>(from: /storage/UsdcVault)
            ?? panic("Could not borrow reference to the owner's Vault!")

        // Withdraw tokens from the signer's stored vault
        vaultRef.approval(uuid: toResourceId, amount: amount)
    }
}
