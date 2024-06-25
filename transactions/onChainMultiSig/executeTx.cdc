// Executes an added Payload for onchain-multisig of a resource
// Note: Currently on supports the returning of a Vault.
// If the payload method returns a vault, it will be deposited to the caller's vault
// other types of returned resource is destroyed (both cases not used in FiatToken)
// 

import "FiatToken"
import "OnChainMultiSig"
import "FungibleToken"

transaction (txIndex: UInt64, resourceAddr: Address, resourcePubSignerPath: PublicPath) {
    let recv: &{FungibleToken.Receiver}
    prepare(oneOfMultiSig: auth(Capabilities) &Account) {
        // Get a reference to the signer's stored vault
        self.recv = oneOfMultiSig.capabilities.get(FiatToken.VaultReceiverPubPath)
            .borrow<&{FungibleToken.Receiver}>()
            ?? panic("Unable to borrow receiver reference for recipient")
    }

    execute {
        let resourceAcct = getAccount(resourceAddr)

        let pubSigRef = resourceAcct.capabilities.get(resourcePubSignerPath)
            .borrow<&{OnChainMultiSig.PublicSigner}>()
            ?? panic("Could not borrow resource pub sig reference")

        let r <- pubSigRef.executeTx(txIndex: txIndex)
        if r != nil {
            // Withdraw tokens from the signer's stored vault
            let vault <- r! as! @{FungibleToken.Vault}
            self.recv.deposit(from: <- vault)
        } else {
            destroy(r)
        }
    }
}
