import USDC from 0x{{.USDCToken}}

transaction {
    prepare (pauser: AuthAccount) {

        let cap = pauser.getCapability<&USDC.Pauser>(/private/UsdcPause).borrow() ?? panic("cannot borrow own private path")
        cap.pause();
    } 

    post {
        USDC.paused: "pause contract error"
    }
}
