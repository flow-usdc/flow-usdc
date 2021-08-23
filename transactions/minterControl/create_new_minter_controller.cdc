import FiatToken from 0x{{.FiatToken}}
import OnChainMultiSig from 0x{{.OnChainMultiSig}}

transaction(minterControllerAddr: Address, publicKeys: [String], pubKeyWeights: [UFix64]) {
    prepare (minterController: AuthAccount) {
        
        // Check and return if they already have a minter controller resource
        if minterController.borrow<&FiatToken.MinterController>(from: FiatToken.MinterControllerStoragePath) != nil {
            minterController.unlink(FiatToken.MinterControllerUUIDPubPath)
            minterController.unlink(FiatToken.MinterControllerPubSigner)
            let m <- minterController.load<@FiatToken.MinterController>(from: FiatToken.MinterControllerStoragePath) 
            destroy m
        }

        var i = 0;
        let pka: [OnChainMultiSig.PubKeyAttr] = []
        while i < pubKeyWeights.length {
            let a = OnChainMultiSig.PubKeyAttr(sa: 1, w: pubKeyWeights[i])
            pka.append(a)
            i = i + 1;
        }
        
        minterController.save(<- FiatToken.createNewMinterController(publicKeys: publicKeys, pubKeyAttrs: pka), to: FiatToken.MinterControllerStoragePath);
        
        minterController.link<&FiatToken.MinterController{FiatToken.ResourceId}>(FiatToken.MinterControllerUUIDPubPath, target: FiatToken.MinterControllerStoragePath)
        ??  panic("Could not link minter controller uuid");

        minterController.link<&FiatToken.MinterController{OnChainMultiSig.PublicSigner}>(FiatToken.MinterControllerPubSigner, target: FiatToken.MinterControllerStoragePath)
        ??  panic("Could not link minter controller public signer");
    } 

    post {
        getAccount(minterControllerAddr).getCapability<&{FiatToken.ResourceId}>(FiatToken.MinterControllerUUIDPubPath).check() :
        "MinterControllerUUID link not set"

        getAccount(minterControllerAddr).getCapability<&{OnChainMultiSig.PublicSigner}>(FiatToken.MinterControllerPubSigner).check() :
        "MinterControllerPubSigner link not set"
    }
}
