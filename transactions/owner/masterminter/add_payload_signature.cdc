// New payload signature to be added to multiSigManager for a particular txIndex 

import FiatToken from 0x{{.FiatToken}}
import FiatTokenInterface from 0x{{.FiatTokenInterface}}
import OnChainMultiSig from 0x{{.OnChainMultiSig}}

transaction (sig: String, txIndex: UInt64, publicKey: String, addr: Address) {
    prepare(oneOfMultiSig: AuthAccount) {
    }

    execute {
       let masterMinterOwnerAcct = getAccount(addr)

        let pubSigRef = masterMinterOwnerAcct.getCapability(FiatToken.MasterMinterPubSigner)
            .borrow<&FiatToken.MasterMinter{OnChainMultiSig.PublicSigner}>()
            ?? panic("Could not borrow master minter pub sig reference"
            
        return pubSigRef.addPayloadSignature(txIndex: txIndex, publicKey: publicKey, sig: sig.decodeHex())
    }
}
