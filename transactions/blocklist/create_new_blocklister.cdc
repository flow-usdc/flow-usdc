import FiatToken from 0x{{.FiatToken}}

transaction(blocklisterAddr: Address) {
    prepare (blocklister: AuthAccount) {
        
        // Check and return if they already have a pauser resource
        if blocklister.borrow<&FiatToken.Blocklister>(from: FiatToken.BlocklisterStoragePath) != nil {
            return
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
