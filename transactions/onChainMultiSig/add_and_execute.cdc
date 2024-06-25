// This combines add_new_payload (without a resource in the payload), add_payload_signature and executeTx
// for a resource 

// `resourcePubSignerPath` must have been linked by the resource owner
// `txIndex` must be the current resource index incremented by 1

import "FiatToken"
import "OnChainMultiSig"
import "FungibleToken"

transaction (sig: [String], txIndex: UInt64, method: String, args: [AnyStruct], publicKey: [String], resourceAddr: Address, resourcePubSignerPath: PublicPath) {
    let rsc: @AnyResource?
    let recv: &{FungibleToken.Receiver}
    prepare(oneOfMultiSig: auth(BorrowValue, IssueStorageCapabilityController, PublishCapability, SaveValue) &Account) {
        self.rsc <- nil
        // Get a reference to the signer's stored vault
        self.recv = oneOfMultiSig.capabilities.get(FiatToken.VaultReceiverPubPath)!
            .borrow<&{FungibleToken.Receiver}>()
            ?? panic("Unable to borrow receiver reference for recipient")
    }

    execute {
        assert(sig.length == publicKey.length, message: "Each signature must have the associated public key")

        // adds new payload with the first sig and pub key 
        let resourceAcct = getAccount(resourceAddr)

        let pubSigRef = resourceAcct.capabilities.get(resourcePubSignerPath)
            .borrow<&{OnChainMultiSig.PublicSigner}>()
            ?? panic("Could not borrow Public Signer reference")
        
        let p <- OnChainMultiSig.createPayload(txIndex: txIndex, method: method, args: args, rsc: <- self.rsc);
        pubSigRef.addNewPayload(payload: <- p, publicKey: publicKey[0], sig: sig[0].decodeHex()) 
        
        if sig.length > 1 {
            var i = 1;
            while i < sig.length {
                pubSigRef.addPayloadSignature(txIndex: txIndex, publicKey: publicKey[i], sig: sig[i].decodeHex())
                i = i + 1 
           } 
        }

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
