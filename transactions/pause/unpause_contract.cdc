import USDC from 0x{{.USDCToken}}

transaction {
    prepare (pauser: AuthAccount) {

        let cap = pauser.getCapability<&USDC.Pauser>(/private/UsdcPause).borrow() ?? panic("cannot borrow own private path")
        cap.unpause();
    } 

    post {
        !USDC.paused: "unpause contract error"
    }
}
