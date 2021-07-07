// This tx is used for blocklister to blocklist a resource.
// This will fail: 
// - if the blocklister does not have delegated capability given by the BlocklistExecutor
// - if the resource has already been blocklisted

import USDC from 0x{{.USDCToken}}

transaction(resourceId: UInt64) {
    prepare (blocklister: AuthAccount) {
        let cap = blocklister.getCapability<&USDC.Blocklister>(/private/UsdcBlocklister).borrow() ?? panic("cannot borrow own private path")
        cap.blocklist(resourceId: resourceId);
    } 

    post {
        USDC.blocklist[resourceId]! != nil: "Resource not blocklisted";
        USDC.blocklist[resourceId] == getCurrentBlock().height : "Blocklisted on incorrect height";

    }
}
