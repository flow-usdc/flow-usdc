// This script creates a new Minter resource.
// If no onchain-multisig is required, empty publicKeys and pubKeyWeights array can be used.
// If account already has a Minter, it will remove it and create a new one. 
// 
// Minter are granted allowance by the UUID.
// If a new one is created, the UUID will be different and will not have the same allowance. 

import "FungibleToken"
import "FiatToken"
import "OnChainMultiSig"

transaction(minterAddr: Address, publicKeys: [String], pubKeyWeights: [UFix64], multiSigAlgos: [UInt8]) {
    prepare (minter: auth(BorrowValue, IssueStorageCapabilityController, PublishCapability, SaveValue) &Account) {
        
        // Check and return if they already have a minter resource
        //assert(minter.borrow<&FiatToken.Minter>(from: FiatToken.MinterStoragePath) != nil, message: "account already has minter resource")
        // DANGER: Remove existing minter if present
        if minter.storage.borrow<&FiatToken.Minter>(from: FiatToken.MinterStoragePath) != nil {
            minter.unlink(FiatToken.MinterUUIDPubPath)
            let m <- minter.storage.load<@FiatToken.Minter>(from: FiatToken.MinterStoragePath) 
            destroy m
        }
        
        var i = 0;
        let pka: [OnChainMultiSig.PubKeyAttr] = []
        while i < pubKeyWeights.length {
            let a = OnChainMultiSig.PubKeyAttr(sa: multiSigAlgos[i], w: pubKeyWeights[i])
            pka.append(a)
            i = i + 1;
        }

        minter.storage.save(<- FiatToken.createNewMinter(), to: FiatToken.MinterStoragePath);

        minter.link<&FiatToken.Minter{FiatToken.ResourceId}>(FiatToken.MinterUUIDPubPath, target: FiatToken.MinterStoragePath)
        ??  panic("Could not link minter uuid");

    } 

    post {
        getAccount(minterAddr).capabilities.get<&{FiatToken.ResourceId}>(FiatToken.MinterUUIDPubPath).check() :
        "MinterUUID link not set"
    }
}
