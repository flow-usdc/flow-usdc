// The account with the BlocklistExecutor Resource can use this script to 
// provide capability for a blocklister to blocklist resources

import FiatToken from 0x{{.FiatToken}}

transaction (blocklister: Address) {
    prepare(blocklistExe: AuthAccount) {
        let cap = blocklistExe.getCapability<&FiatToken.BlocklistExecutor>(FiatToken.BlocklistExecutorPrivPath);
        if !cap.check() {
            panic ("cannot borrow such capability") 
        } else {
            let setCapRef = getAccount(blocklister).getCapability<&FiatToken.Blocklister{FiatToken.BlocklistCapReceiver}>(FiatToken.BlocklisterCapReceiverPubPath).borrow() ?? panic("Cannot get blocklistCapReceiver");
            setCapRef.setBlocklistCap(blocklistCap: cap);
        }
    }

}
