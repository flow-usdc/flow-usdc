// This script gets all the  stored public keys in a multiSigManager for a resource 

import "OnChainMultiSig"
import "FiatToken"

access(all) fun main(resourceAddr: Address, resourcePubSignerPath: PublicPath): [String] {
    let resourceAcct = getAccount(resourceAddr)
    let ref = resourceAcct.capabilities.get<&{OnChainMultiSig.PublicSigner}>(resourcePubSignerPath)
        .borrow()
        ?? panic("Could not borrow Pub Signer reference to the Vault")

    return ref.getSignerKeys()
}
