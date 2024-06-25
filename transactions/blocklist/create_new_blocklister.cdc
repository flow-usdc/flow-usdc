// This creates a new blocklsiter resource.
// If no onchain-multisig is required, empty publicKeys and pubKeyWeights array can be used.
// If account already has a blocklisted, it will remove it and create a new one. 
// 
// Blocklister does not have capability to blocklist until granted by owner of BlocklistExecutor.
// If a new one is created, the capability will be lost

import "FiatToken"
import "OnChainMultiSig"

transaction(blocklisterAddr: Address, publicKeys: [String], pubKeyWeights: [UFix64], multiSigAlgos: [UInt8]) {
    prepare (blocklister: auth(BorrowValue, IssueStorageCapabilityController, PublishCapability, SaveValue) &Account) {
        
        // Check if they already have a blocklister resource, if so, destroy it
        if blocklister.storage.borrow<&FiatToken.Blocklister>(from: FiatToken.BlocklisterStoragePath) != nil {
            blocklister.unlink(FiatToken.BlocklisterCapReceiverPubPath)
            blocklister.unlink(FiatToken.BlocklisterPubSigner)
            let b <- blocklister.storage.load<@FiatToken.Blocklister>(from: FiatToken.BlocklisterStoragePath) 
            destroy b
        }
        
        var i = 0;
        let pka: [OnChainMultiSig.PubKeyAttr] = []
        while i < pubKeyWeights.length {
            let a = OnChainMultiSig.PubKeyAttr(sa: multiSigAlgos[i], w: pubKeyWeights[i])
            pka.append(a)
            i = i + 1;
        }

        blocklister.storage.save(<- FiatToken.createNewBlocklister(publicKeys: publicKeys, pubKeyAttrs: pka), to: FiatToken.BlocklisterStoragePath);
        
        blocklister.link<&FiatToken.Blocklister{FiatToken.BlocklisterCapReceiver}>(FiatToken.BlocklisterCapReceiverPubPath, target: FiatToken.BlocklisterStoragePath)
        ??  panic("Could not link BlocklisterCapReceiver");
        
        blocklister.link<&FiatToken.Blocklister{FiatToken.ResourceId}>(FiatToken.BlocklisterUUIDPubPath, target: FiatToken.BlocklisterStoragePath)
        ??  panic("Could not link Blocklister UUID");

        blocklister.link<&FiatToken.Blocklister{OnChainMultiSig.PublicSigner}>(FiatToken.BlocklisterPubSigner, target: FiatToken.BlocklisterStoragePath)
        ??  panic("Could not link pauser pub signer");
    } 

    post {
        getAccount(blocklisterAddr).capabilities.get<&FiatToken.Blocklister{FiatToken.BlocklisterCapReceiver}>(FiatToken.BlocklisterCapReceiverPubPath).check() :
        "BlocklisterCapReceiver link not set"

        getAccount(blocklisterAddr).capabilities.get<&FiatToken.Blocklister{OnChainMultiSig.PublicSigner}>(FiatToken.BlocklisterPubSigner).check() :
        "BlocklistPubSigner link not set"
    }
}
