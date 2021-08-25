// This transaction is a template for a transaction
// to add a Vault resource to their account
// so that they can use FiatToken 
import FungibleToken from 0x{{.FungibleToken}}
import FiatToken from 0x{{.FiatToken}}
import FiatTokenInterface from 0x{{.FiatTokenInterface}}
import OnChainMultiSig from 0x{{.OnChainMultiSig}}

transaction(multiSigPubKeys: [String], multiSigKeyWeights: [UFix64]) {

    prepare(signer: AuthAccount) {

        // Return early if the account already stores a FiatToken Vault
        if signer.borrow<&FiatToken.Vault>(from: FiatToken.VaultStoragePath) != nil {
            return
        }

        // Create a new ExampleToken Vault and put it in storage
        signer.save(
            <-FiatToken.createEmptyVault(),
            to: FiatToken.VaultStoragePath
        )

        // Create a public capability to the Vault that only exposes
        // the deposit function through the Receiver interface
        signer.link<&FiatToken.Vault{FungibleToken.Receiver}>(
            FiatToken.VaultReceiverPubPath,
            target: FiatToken.VaultStoragePath
        )

        // Create a public capability to the Vault that only exposes
        // the withdrawAllowace function through the WithdrawAllowance interface
        // Anyone can all this method but only those with allowance set will succeed
        signer.link<&FiatToken.Vault{FiatTokenInterface.Allowance}>(
            FiatToken.VaultAllowancePubPath,
            target: FiatToken.VaultStoragePath
        )

        // Create a public capability to the Vault that only exposes
        // the PublicSigner functions 
        // Anyone can all this method but only signatures from added public keys will succeed
        signer.link<&FiatToken.Vault{OnChainMultiSig.PublicSigner}>(
            FiatToken.VaultPubSigner,
            target: FiatToken.VaultStoragePath
        )

        // Create a public capability to the Vault that only exposes
        // the UUID() function through the VaultUUID interface
        signer.link<&FiatToken.Vault{FiatToken.ResourceId}>(
            FiatToken.VaultUUIDPubPath,
            target: FiatToken.VaultStoragePath
        )

        // Create a public capability to the Vault that only exposes
        // the balance field through the Balance interface
        signer.link<&FiatToken.Vault{FungibleToken.Balance}>(
            FiatToken.VaultBalancePubPath,
            target: FiatToken.VaultStoragePath
        )

        // The transaction that creates the vault can also add required multiSig public keys to the multiSigManager
        let s = signer.borrow<&FiatToken.Vault>(from: FiatToken.VaultStoragePath) ?? panic ("cannot borrow own resource")
        s.addKeys(multiSigPubKeys: multiSigPubKeys, multiSigKeyWeights: multiSigKeyWeights)
    }
}
