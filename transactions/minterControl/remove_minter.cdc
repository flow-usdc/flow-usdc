// MinterController uses this to remove Minter 
// A Minter must have been configured and under such control

import FiatToken from 0x{{.FiatToken}}

transaction () {
    prepare(minterController: AuthAccount) {
        let mc = minterController.borrow<&FiatToken.MinterController>(from: FiatToken.MinterControllerStoragePath) 
            ?? panic ("no minter controller resource avaialble");
        mc.removeMinter();
    }
}
