// The account with the PauseExecutor Resource can use this script to 
// provide capability for a pauser to pause the contract

import USDC from 0x{{.USDCToken}}

transaction (blocklister: Address, blocklistCapPath: PublicPath) {
    prepare(blocklistExe: AuthAccount) {
        let cap = blocklistExe.getCapability<&USDC.BlocklistExecutor>(USDC.BlocklistExecutorPrivPath);
        if !cap.check() {
            panic ("cannot borrow such capability") 
        } else {
            let setCapRef = getAccount(blocklister).getCapability<&USDC.Blocklister{USDC.BlocklistCapReceiver}>(blocklistCapPath).borrow() ?? panic("Cannot get blocklistCapReceiver");
            setCapRef.setBlocklistCap(blocklistCap: cap);
        }
    }

}
