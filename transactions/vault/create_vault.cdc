// This script is used to add a Vault resource to their account so that they can use FiatToken 
//
// If the Vault already exist for the account, the script will return immediately without error
// 
import "FungibleToken"
import "FiatToken"

transaction {

    prepare(signer: auth(Storage, BorrowValue, Capabilities, AddContract) &Account) {

        // Return early if the account already stores a FiatToken Vault
        if signer.storage.borrow<&FiatToken.Vault>(from: FiatToken.VaultStoragePath) != nil {
            return
        }

        // Create a new ExampleToken Vault and put it in storage
        signer.storage.save(
            <-FiatToken.createEmptyVault(vaultType: Type<@FiatToken.Vault>()),
            to: FiatToken.VaultStoragePath
        )

        // Create a public capability to the Vault that only exposes
        // the deposit function through the Receiver interface
        let receiver = signer.capabilities.storage.issue<&FiatToken.Vault>(
            FiatToken.VaultStoragePath
        )
        signer.capabilities.publish(receiver, at: FiatToken.VaultReceiverPubPath)
        
        // Create a public capability to the Vault that only exposes
        // the balance field through the Balance interface
        signer.capabilities.publish(receiver, at: FiatToken.VaultBalancePubPath)

    }
}
