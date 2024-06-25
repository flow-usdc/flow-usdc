// New payload (without a resource in the payload) to be added to multiSigManager for a resource 
// `resourcePubSignerPath` must have been linked by the resource owner
// `txIndex` must be the current resource index incremented by 1

import "FiatToken"
import "OnChainMultiSig"

transaction (sig: String, txIndex: UInt64, method: String, args: [AnyStruct], publicKey: String, resourceAddr: Address, resourcePubSignerPath: PublicPath) {
    let rsc: @AnyResource?
    prepare(oneOfMultiSig: &Account) {
        self.rsc <- nil
    }

    execute {
        let resourceAcct = getAccount(resourceAddr)

        let pubSigRef = resourceAcct.getCapability(resourcePubSignerPath)
            .borrow<&{OnChainMultiSig.PublicSigner}>()
            ?? panic("Could not borrow Public Signer reference")
        
        let p <- OnChainMultiSig.createPayload(txIndex: txIndex, method: method, args: args, rsc: <- self.rsc);
        return pubSigRef.addNewPayload(payload: <- p, publicKey: publicKey, sig: sig.decodeHex()) 
    }
}
