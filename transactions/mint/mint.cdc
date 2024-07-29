// This script mints token on FiatToken contract and deposits
// the minted amount to the receiver's Vault

import "FungibleToken"
import "FiatToken"
import "FlowEVMBridgeHandlerInterfaces"

transaction(recipient: Address, amount: UFix64) {

    /// Reference to the Example Token Minter Resource object
    let tokenMinter: auth(FlowEVMBridgeHandlerInterfaces.Mint) &FiatToken.MinterResource

    /// Reference to the Fungible Token Receiver of the recipient
    let tokenReceiver: &{FungibleToken.Receiver}

    prepare(signer: auth(BorrowValue) &Account) {

        // Borrow a reference to the admin object
        self.tokenMinter = signer.storage.borrow<auth(FlowEVMBridgeHandlerInterfaces.Mint) &FiatToken.MinterResource>(from: FiatToken.MinterStoragePath)
            ?? panic("Signer is not the minter")
    
        self.tokenReceiver = getAccount(recipient).capabilities.borrow<&FiatToken.Vault>(FiatToken.VaultReceiverPubPath)
            ?? panic("Could not borrow receiver reference to the Vault")
    }

    execute {

        // Create mint tokens
        let mintedVault <- self.tokenMinter.mint(amount: amount)

        // Deposit them to the receiever
        self.tokenReceiver.deposit(from: <-mintedVault)
    }
}