// Masterminter uses this to configure which minter the minter controller manages

import FiatToken from 0x{{.FiatToken}}
import FiatTokenInterface from 0x{{.FiatTokenInterface}}
import OnChainMultiSig from 0x{{.OnChainMultiSig}}

transaction (addr: Address, txIndex: UInt64) {
    prepare(oneOfMultiSig: AuthAccount) {
    }

    execute {
        // Get the recipient's public account object
        let masterMinterOwnerAcct = getAccount(addr)

        // Get a allowance reference to the fromAcct's vault 
        let pubSigRef = masterMinterOwnerAcct.getCapability(FiatToken.MasterMinterPubSigner)
            .borrow<&FiatToken.MasterMinter{OnChainMultiSig.PublicSigner}>()
            ?? panic("Could not borrow master minter pub sig reference")
            
        return pubSigRef.executeTx(txIndex: txIndex) 
    }
}
