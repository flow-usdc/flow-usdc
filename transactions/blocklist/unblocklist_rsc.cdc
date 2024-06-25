// This tx is used for blocklister to blocklist a resource.
// This will fail: 
// - if the blocklister does not have delegated capability given by the BlocklistExecutor
// - if the resource is not currently blocklisted

import "FiatToken"

transaction(resourceId: UInt64) {
    prepare (blocklister: auth(BorrowValue) &Account) {
        let blocklister = blocklister.storage.borrow<&FiatToken.Blocklister>(from: FiatToken.BlocklisterStoragePath) ?? panic("cannot borrow own private path")
        blocklister.unblocklist(resourceId: resourceId);
    } 

    post {
        FiatToken.getBlocklist(resourceId: resourceId) == nil : "Resource still on blocklist"
    }
}
