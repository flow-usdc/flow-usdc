import FiatToken from 0x{{.FiatToken}}

transaction(pauserAddr: Address) {
    prepare (pauser: AuthAccount) {
        
        // Check and return if they already have a pauser resource
        if pauser.borrow<&FiatToken.Pauser>(from: FiatToken.PauserStoragePath) != nil {
            return
        }
        
        pauser.save(<- FiatToken.createNewPauser(), to: FiatToken.PauserStoragePath);
        
        log(FiatToken.PauserStoragePath);
        log(FiatToken.PauserCapReceiverPubPath);
        
        pauser.link<&FiatToken.Pauser{FiatToken.PauseCapReceiver}>(FiatToken.PauserCapReceiverPubPath, target: FiatToken.PauserStoragePath)
        ??  panic("Could not link PauserCapReceiver");
    } 

    post {
        getAccount(pauserAddr).getCapability<&FiatToken.Pauser{FiatToken.PauseCapReceiver}>(FiatToken.PauserCapReceiverPubPath).check() :
        "PauserCapReceiver link not set"
    }
}
