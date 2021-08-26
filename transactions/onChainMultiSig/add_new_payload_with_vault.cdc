// New payload with a Vault resource to be added to multiSigManager for a resource
// 
// `resourcePubSignerPath` must have been linked by the resource owner
// `txIndex` must be the current resource index incremented by 1
// The first argument in `args` must be the balance in the vault
import FiatToken from 0x{{.FiatToken}}
import FiatTokenInterface from 0x{{.FiatTokenInterface}}
import OnChainMultiSig from 0x{{.OnChainMultiSig}}

transaction (sig: String, txIndex: UInt64, method: String, args: [AnyStruct], publicKey: String, resourceAddr: Address, resourcePubSignerPath: PublicPath) {
    let rsc: @AnyResource?
    prepare(oneOfMultiSig: AuthAccount) {

        // Get a reference to the signer's stored vault
        let vaultRef = oneOfMultiSig.borrow<&FiatToken.Vault>(from: FiatToken.VaultStoragePath)
            ?? panic("Could not borrow reference to the owner's Vault!")

        // Withdraw tokens from the signer's stored vault
        let amount = args[0] as? UFix64 ?? panic("cannot downcast first arg as amount");
        self.rsc <- vaultRef.withdraw(amount: amount);
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
