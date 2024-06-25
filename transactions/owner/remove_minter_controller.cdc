// Masterminter uses this to remove MinterController
// Minter previously assigned allowances will still be valid.

import "FiatToken"

transaction (minterController: UInt64) {
    prepare(masterMinter: auth(BorrowValue) &Account) {
        let mm = masterMinter.storage.borrow<&FiatToken.MasterMinter>(from: FiatToken.MasterMinterStoragePath)
            ?? panic ("no masterminter resource avaialble");

        mm.removeMinterController(minterController: minterController);
    }
    post {
        FiatToken.getManagedMinter(resourceId: minterController) == nil : "minterController not removed"
    }
}
