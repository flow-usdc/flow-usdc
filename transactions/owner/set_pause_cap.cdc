// The account with the PauseExecutor Resource can use this script to 
// provide capability for a pauser to pause the contract

import USDC from 0x{{.USDCToken}}

transaction (pauser: Address, pauseCapPath: PublicPath) {
    prepare(pauseExe: AuthAccount) {
        let cap = pauseExe.getCapability<&USDC.PauseExecutor>(USDC.PauseExecutorPrivPath);
        if !cap.check() {
            return
        } else {
            let setCapRef = getAccount(pauser).getCapability<&USDC.Pauser{USDC.PauseCapReceiver}>(pauseCapPath).borrow() ?? panic("Cannot get pauseCapReceiver");
            setCapRef.setPauseCap(pauseCap: cap);
        }

    }

}
