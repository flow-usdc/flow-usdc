// This script is used to add a Vault resource to their account so that they can use FiatToken 
//
// If the Vault already exist for the account, the script will return immediately without error
// 
// If not onchain-multisig is required, pubkeys and key weights can be empty
// Vault resource must follow the FuntibleToken interface where initialiser only takes the balance
// As a result, the Vault owner is required to directly add public keys to the OnChainMultiSig.Manager
// via the `addKeys` method in the OnchainMultiSig.KeyManager interface.
// 
// Therefore if multisig is required for the vault, the account itself should have the same key weight
// distribution as it does for the Vault.
import "FungibleToken"
import "FiatToken"
import "OnChainMultiSig"

transaction {

    prepare(signer: auth(BorrowValue, IssueStorageCapabilityController, PublishCapability, SaveValue) &Account) {

        // Return early if the account already stores a FiatToken Vault
        if signer.storage.borrow<&FiatToken.Vault>(from: FiatToken.VaultStoragePath) != nil {
            return
        }

        let vault <- FiatToken.createEmptyVault(vaultType: Type<@FiatToken.Vault>())

        // Create a new FiatToken Vault and put it in storage
        signer.storage.save(<-vault, to: FiatToken.VaultStoragePath)

        // Create a public capability to the Vault that exposes the Vault interfaces
        let vaultCap = signer.capabilities.storage.issue<&FiatToken.Vault>(
            FiatToken.VaultStoragePath
        )
        signer.capabilities.publish(vaultCap, at: FiatToken.VaultUUIDPubPath)
        signer.capabilities.publish(vaultCap, at: FiatToken.VaultReceiverPubPath)
        signer.capabilities.publish(vaultCap, at: FiatToken.VaultBalancePubPath)
    }
}
