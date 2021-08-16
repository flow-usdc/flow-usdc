import FiatToken from 0x{{.FiatToken}}

transaction(minterControllerAddr: Address) {
    prepare (minterController: AuthAccount) {
        
        // Check and return if they already have a minter controller resource
        if minterController.borrow<&FiatToken.MinterController>(from: FiatToken.MinterControllerStoragePath) != nil {
            minterController.unlink(FiatToken.MinterControllerUUIDPubPath)
            let m <- minterController.load<@FiatToken.MinterController>(from: FiatToken.MinterControllerStoragePath) 
            destroy m
        }
        
        minterController.save(<- FiatToken.createNewMinterController(), to: FiatToken.MinterControllerStoragePath);
        
        minterController.link<&FiatToken.MinterController{FiatToken.ResourceId}>(FiatToken.MinterControllerUUIDPubPath, target: FiatToken.MinterControllerStoragePath)
        ??  panic("Could not link minter controller uuid");
    } 

    post {
        getAccount(minterControllerAddr).getCapability<&{FiatToken.ResourceId}>(FiatToken.MinterControllerUUIDPubPath).check() :
        "MinterControllerUUID link not set"
    }
}
