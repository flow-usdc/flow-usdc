// This script is used by Vault owner to approve an allowance for another Vault

import FiatToken from 0x{{.FiatToken}}

transaction(toResourceId: UInt64, amount: UFix64) {

    prepare (fromAcct: AuthAccount) {
        // Get a reference to the signer's stored vault
        let vaultRef = fromAcct.borrow<&FiatToken.Vault>(from: FiatToken.VaultStoragePath)
            ?? panic("Could not borrow reference to the owner's Vault!")

        // Withdraw tokens from the signer's stored vault
        vaultRef.approval(resourceId: toResourceId, amount: amount)
    }
}
