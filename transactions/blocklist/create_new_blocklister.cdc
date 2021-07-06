import USDC from 0x{{.USDCToken}}

transaction(blocklisterAddr: Address) {
    prepare (blocklister: AuthAccount) {
        
        // Check and return if they already have a pauser resource
        if blocklister.borrow<&USDC.Blocklister>(from: /storage/UsdcBlocklister) != nil {
            return
        }
        
        blocklister.save(<- USDC.createNewBlocklister(), to: /storage/UsdcBlocklister);
        
        blocklister.link<&USDC.Blocklister{USDC.BlocklistCapReceiver}>(/public/UsdcBlocklistCapReceiver, target: /storage/UsdcBlocklister)
        ??  panic("Could not link BlocklistCapReceiver");

        blocklister.link<&USDC.Blocklister>(/private/UsdcBlocklister, target: /storage/UsdcBlocklister)
        ??  panic("Could not link BlocklistCap");
        
    } 

    post {
        getAccount(blocklisterAddr).getCapability<&USDC.Blocklister{USDC.BlocklistCapReceiver}>(/public/UsdcBlocklistCapReceiver).check() :
        "BlocklistCapReceiver link not set"
    }
}
