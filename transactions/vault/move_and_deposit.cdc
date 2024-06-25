// This transaction is used by accounts with a FiatToken Vault to move it and deposit
// its content into other vault

import "FungibleToken"
import "FiatToken"

transaction( to: Address) {

    // The Vault resource that holds the tokens that are being transferred
    let sentVault: @FiatToken.Vault

    prepare(signer: auth(Storage) &Account) {

        // Move self vault 
        self.sentVault <- signer.storage.load<@FiatToken.Vault>(from: FiatToken.VaultStoragePath)
            ?? panic("Could not load the owner's Vault!")
    }

    execute {

        // Get the recipient's public account object
        let recipient = getAccount(to)

        // Get a reference to the recipient's Receiver
        let receiverRef = recipient.capabilities.borrow<&{FungibleToken.Receiver}>(FiatToken.VaultReceiverPubPath)
            ?? panic("Could not borrow receiver reference to the recipient's Vault")

        // Deposit the withdrawn tokens in the recipient's receiver
        receiverRef.deposit(from: <-self.sentVault)
    }
}
