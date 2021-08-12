// This script gets the current TxIndex for payloads stored in multiSigManager in a resource 
// The new payload must be this value + 1

import OnChainMultiSig from 0x{{.OnChainMultiSig}}
import FiatToken from 0x{{.FiatToken}}
import FiatTokenInterface from 0x{{.FiatTokenInterface}}

pub fun main(account: Address): UInt64{
    let acct = getAccount(account)
    let ref = acct.getCapability(FiatToken.MasterMinterPubSigner)
        .borrow<&FiatToken.MasterMinter{OnChainMultiSig.PublicSigner}>()
        ?? panic("Could not borrow Pub Signer reference to MasterMinter")

    return ref.getTxIndex()
}
