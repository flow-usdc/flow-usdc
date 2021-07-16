import FiatToken from 0x{{.FiatToken}}

transaction(blocklisterAddr: Address) {
    prepare (blocklister: AuthAccount) {
        
        // Check if they already have a blocklister resource, if so, destroy it
        if blocklister.borrow<&FiatToken.Blocklister>(from: FiatToken.BlocklisterStoragePath) != nil {
            blocklister.unlink(FiatToken.BlocklisterCapReceiverPubPath)
            let b <- blocklister.load<@FiatToken.Blocklister>(from: FiatToken.BlocklisterStoragePath) 
            destroy b
        }
        
        blocklister.save(<- FiatToken.createNewBlocklister(), to: FiatToken.BlocklisterStoragePath);
        
        blocklister.link<&FiatToken.Blocklister{FiatToken.BlocklistCapReceiver}>(FiatToken.BlocklisterCapReceiverPubPath, target: FiatToken.BlocklisterStoragePath)
        ??  panic("Could not link BlocklistCapReceiver");
    } 

    post {
        getAccount(blocklisterAddr).getCapability<&FiatToken.Blocklister{FiatToken.BlocklistCapReceiver}>(FiatToken.BlocklisterCapReceiverPubPath).check() :
        "BlocklistCapReceiver link not set"
    }
}
