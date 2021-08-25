// This transaction is used by accounts with a FiatToken Vault to move it and deposit
// its content into other vault

import FungibleToken from 0x{{.FungibleToken}}
import FiatToken from 0x{{.FiatToken}}

transaction( to: Address) {

    // The Vault resource that holds the tokens that are being transferred
    let sentVault: @FiatToken.Vault

    prepare(signer: AuthAccount) {

        // Move self vault 
        self.sentVault <- signer.load<@FiatToken.Vault>(from: FiatToken.VaultStoragePath)
            ?? panic("Could not load the owner's Vault!")
    }

    execute {

        // Get the recipient's public account object
        let recipient = getAccount(to)

        // Get a reference to the recipient's Receiver
        let receiverRef = recipient.getCapability(FiatToken.VaultReceiverPubPath)
            .borrow<&{FungibleToken.Receiver}>()
            ?? panic("Could not borrow receiver reference to the recipient's Vault")

        // Deposit the tokens 
        receiverRef.deposit(from: <-self.sentVault)
    }
}
