// This tx is used for blocklister to blocklist a resource.
// This will fail: 
// - if the blocklister does not have delegated capability given by the BlocklistExecutor
// - if the resource is not currently blocklisted

import USDC from 0x{{.USDCToken}}

transaction(resourceId: UInt64) {
    prepare (blocklister: AuthAccount) {
        let cap = blocklister.getCapability<&USDC.Blocklister>(/private/UsdcBlocklister).borrow() ?? panic("cannot borrow own private path")
        cap.unblocklist(resourceId: resourceId);
    } 

    post {
        USDC.blocklist[resourceId] == nil : "Resource still on blocklist"
    }
}
