// This transaction is a template for a transaction
// to add a Vault resource to their account
// so that they can use USDC 
import FungibleToken from 0x{{.FungibleToken}}
import USDC from 0x{{.USDCToken}}
import USDCInterface from 0x{{.USDCInterface}}

transaction {

    prepare(signer: AuthAccount) {

        // Return early if the account already stores a USDC Vault
        if signer.borrow<&USDC.Vault>(from: /storage/UsdcVault) != nil {
            return
        }

        // Create a new ExampleToken Vault and put it in storage
        signer.save(
            <-USDC.createEmptyVault(),
            to: /storage/UsdcVault
        )

        // Create a public capability to the Vault that only exposes
        // the deposit function through the Receiver interface
        signer.link<&USDC.Vault{FungibleToken.Receiver}>(
            /public/UsdcReceiver,
            target: /storage/UsdcVault
        )

        // Create a public capability to the Vault that only exposes
        // the UUID() function through the VaultUUID interface
        signer.link<&USDC.Vault{USDCInterface.VaultUUID}>(
            /public/UsdcVaultUUID,
            target: /storage/UsdcVault
        )

        // Create a public capability to the Vault that only exposes
        // the balance field through the Balance interface
        signer.link<&USDC.Vault{FungibleToken.Balance}>(
            /public/UsdcBalance,
            target: /storage/UsdcVault
        )
    }
}
