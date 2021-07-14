import FiatToken from 0x{{.FiatToken}}

transaction(minterAddr: Address) {
    prepare (minter: AuthAccount) {
        
        // Check and return if they already have a minter resource
        if minter.borrow<&FiatToken.Minter>(from: FiatToken.MinterStoragePath) != nil {
            return
        }
        
        minter.save(<- FiatToken.createNewMinter(), to: FiatToken.MinterStoragePath);
        
        minter.link<&FiatToken.Minter{FiatToken.ResourceId}>(FiatToken.MinterUUIDPubPath, target: FiatToken.MinterStoragePath)
        ??  panic("Could not link minter uuid");
    } 

    post {
        getAccount(minterAddr).getCapability<&{FiatToken.ResourceId}>(FiatToken.MinterUUIDPubPath).check() :
        "MinterUUID link not set"
    }
}
