import FiatToken from 0x{{.FiatToken}}
import OnChainMultiSig from 0x{{.OnChainMultiSig}}

transaction(minterAddr: Address, publicKeys: [String], pubKeyWeights: [UFix64]) {
    prepare (minter: AuthAccount) {
        
        // Check and return if they already have a minter resource
        if minter.borrow<&FiatToken.Minter>(from: FiatToken.MinterStoragePath) != nil {
            minter.unlink(FiatToken.MinterUUIDPubPath)
            minter.unlink(FiatToken.MinterPubSigner)
            let m <- minter.load<@FiatToken.Minter>(from: FiatToken.MinterStoragePath) 
            destroy m
        }
        
        var i = 0;
        let pka: [OnChainMultiSig.PubKeyAttr] = []
        while i < pubKeyWeights.length {
            let a = OnChainMultiSig.PubKeyAttr(sa: 1, w: pubKeyWeights[i])
            pka.append(a)
            i = i + 1;
        }
        
        minter.save(<- FiatToken.createNewMinter(publicKeys: publicKeys, pubKeyAttrs: pka), to: FiatToken.MinterStoragePath);
        
        minter.link<&FiatToken.Minter{FiatToken.ResourceId}>(FiatToken.MinterUUIDPubPath, target: FiatToken.MinterStoragePath)
        ??  panic("Could not link minter uuid");

        minter.link<&FiatToken.Minter{OnChainMultiSig.PublicSigner}>(FiatToken.MinterPubSigner, target: FiatToken.MinterStoragePath)
        ??  panic("Could not link minter pub signer");
    } 

    post {
        getAccount(minterAddr).getCapability<&{FiatToken.ResourceId}>(FiatToken.MinterUUIDPubPath).check() :
        "MinterUUID link not set"

        getAccount(minterAddr).getCapability<&{OnChainMultiSig.PublicSigner}>(FiatToken.MinterPubSigner).check() :
        "MinterPubSigner link not set"
    }
}
