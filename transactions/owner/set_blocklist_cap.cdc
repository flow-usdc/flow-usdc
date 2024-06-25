// The account with the BlocklistExecutor Resource can use this script to 
// provide capability for a blocklister to blocklist resources

import "FiatToken"

transaction (blocklister: Address) {
    prepare(blocklistExe: auth(BorrowValue) &Account) {
        let cap = blocklistExe.capabilities.get<&FiatToken.BlocklistExecutor>(FiatToken.BlocklistExecutorPrivPath);
        if !cap.check() {
            panic ("cannot borrow such capability") 
        } else {
            let setCapRef = getAccount(blocklister).capabilities.get<&FiatToken.Blocklister{FiatToken.BlocklistCapReceiver}>(FiatToken.BlocklisterCapReceiverPubPath).borrow() ?? panic("Cannot get blocklistCapReceiver");
            setCapRef.setBlocklistCap(blocklistCap: cap);
        }
    }

}
