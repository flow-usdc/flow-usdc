// This script withdraws tokens from minter own vault to burn the tokens
// Minter can burn tokens from a given vault

import "FungibleToken"
import "FiatToken"

transaction(amount: UFix64) {

    prepare(minter: auth(BorrowValue) &Account) {

        // Get a reference to the signer's stored vault
        let vaultRef = minter.storage.borrow<auth(FungibleToken.Withdraw) &FiatToken.Vault>(from: FiatToken.VaultStoragePath)
            ?? panic("Could not borrow reference to the owner's Vault!")

        // Withdraw tokens from the minter's stored vault
        let burnVault <- vaultRef.withdraw(amount: amount)

        let m = minter.storage.borrow<&FiatToken.Minter>(from: FiatToken.MinterStoragePath) 
            ?? panic ("no minter resource avaialble");

        m.burn(vault: <-burnVault);
    }
}
