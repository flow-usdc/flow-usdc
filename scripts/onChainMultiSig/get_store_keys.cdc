// This script gets all the  stored public keys in a multiSigManager for a resource 

import OnChainMultiSig from 0x{{.OnChainMultiSig}}
import FiatToken from 0x{{.FiatToken}}

pub fun main(resourceAddr: Address, resourcePubSignerPath: PublicPath): [String] {
    let resourceAcct = getAccount(resourceAddr)
    let ref = resourceAcct.getCapability(resourcePubSignerPath)
        .borrow<&{OnChainMultiSig.PublicSigner}>()
        ?? panic("Could not borrow Pub Signer reference to the Vault")

    return ref.getSignerKeys()
}
