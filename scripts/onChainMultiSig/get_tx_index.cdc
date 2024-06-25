// This script gets the current TxIndex for payloads stored in multiSigManager in a resource 
// The new payload must be this value + 1

import "OnChainMultiSig"
import "FiatToken"

access(all) fun main(resourceAddr: Address, resourcePubSignerPath: PublicPath): UInt64{
    let resourcAcct = getAccount(resourceAddr)
    let ref = resourcAcct.capabilities.get<&{OnChainMultiSig.PublicSigner}>(resourcePubSignerPath)
        .borrow()
        ?? panic("Could not borrow Pub Signer reference to Resource")

    return ref.getTxIndex()
}
