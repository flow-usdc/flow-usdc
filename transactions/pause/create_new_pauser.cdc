import FiatToken from 0x{{.FiatToken}}

transaction(pauserAddr: Address) {
    prepare (pauser: AuthAccount) {
        
        // Check if account already have a pauser resource, if so destroy it
        if pauser.borrow<&FiatToken.Pauser>(from: FiatToken.PauserStoragePath) != nil {
            pauser.unlink(FiatToken.PauserCapReceiverPubPath)
            let p <- pauser.load<@FiatToken.Pauser>(from: FiatToken.PauserStoragePath) 
            destroy p
        }
        
        pauser.save(<- FiatToken.createNewPauser(), to: FiatToken.PauserStoragePath);
        log("created new pauser")
        
        pauser.link<&FiatToken.Pauser{FiatToken.PauseCapReceiver}>(FiatToken.PauserCapReceiverPubPath, target: FiatToken.PauserStoragePath)
        ??  panic("Could not link PauserCapReceiver");
    } 

    post {
        getAccount(pauserAddr).getCapability<&FiatToken.Pauser{FiatToken.PauseCapReceiver}>(FiatToken.PauserCapReceiverPubPath).check() :
        "PauserCapReceiver link not set"
    }
}
