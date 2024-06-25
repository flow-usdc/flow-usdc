// Masterminter uses this to configure which Minter the MinterController manages

import "FiatToken"

transaction (minter: UInt64, minterController: UInt64) {
    prepare(masterMinter: auth(BorrowValue) &Account) {
        let mm = masterMinter.storage.borrow<&FiatToken.MasterMinter>(from: FiatToken.MasterMinterStoragePath) 
            ?? panic ("no masterminter resource avaialble");

        mm.configureMinterController(minter: minter, minterController: minterController);
    }
    post {
        FiatToken.getManagedMinter(resourceId: minterController) == minter : "minterController not configured"
    }
}
