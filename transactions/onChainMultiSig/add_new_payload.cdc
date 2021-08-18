// New payload to be added to multiSigManager for a resource 
import FiatToken from 0x{{.FiatToken}}
import FiatTokenInterface from 0x{{.FiatTokenInterface}}
import OnChainMultiSig from 0x{{.OnChainMultiSig}}

transaction (sig: String, txIndex: UInt64, method: String, args: [AnyStruct], publicKey: String, resourceAddr: Address, resourcePubSignerPath: PublicPath) {
    prepare(oneOfMultiSig: AuthAccount) {
    }

    execute {
        let resourceAcct = getAccount(resourceAddr)

        let pubSigRef = resourceAcct.getCapability(resourcePubSignerPath)
            .borrow<&{OnChainMultiSig.PublicSigner}>()
            ?? panic("Could not borrow Public Signer reference")
        
        let p = OnChainMultiSig.PayloadDetails(txIndex: txIndex, method: method, args: args);
        return pubSigRef.addNewPayload(payload: p, publicKey: publicKey, sig: sig.decodeHex()) 
    }
}
