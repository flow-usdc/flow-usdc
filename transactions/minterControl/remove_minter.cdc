// MinterController uses this to remove Minter 
// A Minter must have been configured and under such control

import "FiatToken"

transaction () {
    prepare(minterController: auth(BorrowValue) &Account) {
        let mc = minterController.storage.borrow<&FiatToken.MinterController>(from: FiatToken.MinterControllerStoragePath) 
            ?? panic ("no minter controller resource avaialble");
        mc.removeMinter();
    }
}
