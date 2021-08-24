// This script gets the current TxIndex for payloads stored in multiSigManager in a resource 
// The new payload must be this value + 1

import OnChainMultiSig from 0x{{.OnChainMultiSig}}
import FiatToken from 0x{{.FiatToken}}

pub fun main(resourceAddr: Address, resourcePubSignerPath: PublicPath): UInt64{
    let resourcAcct = getAccount(resourceAddr)
    let ref = resourcAcct.getCapability(resourcePubSignerPath)
        .borrow<&{OnChainMultiSig.PublicSigner}>()
        ?? panic("Could not borrow Pub Signer reference to Resource")

    return ref.getTxIndex()
}
