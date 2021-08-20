// Masterminter uses this to configure which minter the minter controller manages

import FiatToken from 0x{{.FiatToken}}
import FiatTokenInterface from 0x{{.FiatTokenInterface}}
import OnChainMultiSig from 0x{{.OnChainMultiSig}}

transaction (txIndex: UInt64, resourceAddr: Address, resourcePubSignerPath: PublicPath) {
    prepare(oneOfMultiSig: AuthAccount) {
    }

    execute {
        let resourceAcct = getAccount(resourceAddr)

        let pubSigRef = resourceAcct.getCapability(resourcePubSignerPath)
            .borrow<&{OnChainMultiSig.PublicSigner}>()
            ?? panic("Could not borrow master minter pub sig reference")
            
        let r <- pubSigRef.executeTx(txIndex: txIndex)
        destroy(r)
    }
}
