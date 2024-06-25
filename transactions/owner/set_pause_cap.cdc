// The account with the PauseExecutor Resource can use this script to 
// provide capability for a pauser to pause the contract

import "FiatToken"

transaction (pauser: Address) {
    prepare(pauseExe: auth(BorrowValue) &Account) {
        let cap = pauseExe.capabilities.get<&FiatToken.PauseExecutor>(FiatToken.PauseExecutorPrivPath);
        if !cap.check() {
            panic ("cannot borrow such capability") 
        } else {
            let setCapRef = getAccount(pauser).capabilities.get<&FiatToken.Pauser{FiatToken.PauseCapReceiver}>(FiatToken.PauserCapReceiverPubPath).borrow() ?? panic("Cannot get pauseCapReceiver");
            setCapRef.setPauseCap(cap: cap);
        }
    }

}
