// New payload signature to be added to multiSigManager for a particular txIndex 

import "FiatToken"
import "OnChainMultiSig"

transaction (sig: String, txIndex: UInt64, publicKey: String, resourceAddr: Address, resourcePubSignerPath: PublicPath) {
    prepare(oneOfMultiSig: &Account) {
    }

    execute {
       let resourceAcct = getAccount(resourceAddr)

        let pubSigRef = resourceAcct.capabilities.get(resourcePubSignerPath)
            .borrow<&{OnChainMultiSig.PublicSigner}>()
            ?? panic("Could not borrow master minter pub sig reference")
            
        return pubSigRef.addPayloadSignature(txIndex: txIndex, publicKey: publicKey, sig: sig.decodeHex())
    }
}
