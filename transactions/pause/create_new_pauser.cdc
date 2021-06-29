import USDC from 0x{{.USDCToken}}

transaction {
    prepare (pauser: AuthAccount) {
        
        // Check and return if they already have a pauser resource
        if pauser.borrow<&USDC.Pauser>(from: /storage/UsdcPauser) != nil {
            return
        }
        
        pauser.save(<- USDC.createNewPauser(), to: /storage/UsdcPauser);
        
        pauser.link<&USDC.Pauser{USDC.PauseCapReceiver}>(/public/UsdcPauseCapReceiver, target: /storage/UsdcPauser)
        ??  panic("Could not link PauserCapReceiver");

        pauser.link<&USDC.Pauser>(/private/UsdcPause, target: /storage/UsdcPauser)
        ??  panic("Could not link pauserCap");
        
    } 
}