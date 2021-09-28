// This creates a new pauser resource.
// If no onchain-multisig is required, empty publicKeys and pubKeyWeights array can be used.
// If account already has a Pauser, it will remove it and create a new one. 
// 
// Pauser does not have capability to blocklist until granted by owner of PauseExecutor.
// If a new one is created, the capability will be lost

import FiatToken from 0x{{.FiatToken}}
import OnChainMultiSig from 0x{{.OnChainMultiSig}}

transaction(pauserAddr: Address, publicKeys: [String], pubKeyWeights: [UFix64], multiSigAlgos: [UInt8]) {

    prepare (pauser: AuthAccount) {
        
        // Check if account already have a pauser resource, if so destroy it
        if pauser.borrow<&FiatToken.Pauser>(from: FiatToken.PauserStoragePath) != nil {
            pauser.unlink(FiatToken.PauserCapReceiverPubPath)
            pauser.unlink(FiatToken.PauserPubSigner)
            let p <- pauser.load<@FiatToken.Pauser>(from: FiatToken.PauserStoragePath) 
            destroy p
        }
        
        var i = 0;
        let pka: [OnChainMultiSig.PubKeyAttr] = []
        while i < pubKeyWeights.length {
            let a = OnChainMultiSig.PubKeyAttr(sa: multiSigAlgos[i], w: pubKeyWeights[i])
            pka.append(a)
            i = i + 1;
        }

        pauser.save(<- FiatToken.createNewPauser(publicKeys: publicKeys, pubKeyAttrs: pka), to: FiatToken.PauserStoragePath);
        log("created new pauser")
        
        pauser.link<&FiatToken.Pauser{FiatToken.PauseCapReceiver}>(FiatToken.PauserCapReceiverPubPath, target: FiatToken.PauserStoragePath)
        ??  panic("Could not link PauserCapReceiver");

        pauser.link<&FiatToken.Pauser{OnChainMultiSig.PublicSigner}>(FiatToken.PauserPubSigner, target: FiatToken.PauserStoragePath)
        ??  panic("Could not link pauser pub signer");
    } 

    post {
        getAccount(pauserAddr).getCapability<&FiatToken.Pauser{FiatToken.PauseCapReceiver}>(FiatToken.PauserCapReceiverPubPath).check() :
        "PauserCapReceiver link not set"

        getAccount(pauserAddr).getCapability<&FiatToken.Pauser{OnChainMultiSig.PublicSigner}>(FiatToken.PauserPubSigner).check() :
        "PauserPubSigner link not set"
    }
}
