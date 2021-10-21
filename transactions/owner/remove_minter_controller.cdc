// Masterminter uses this to remove MinterController
// Minter previously assigned allowances will still be valid.

import FiatToken from 0x{{.FiatToken}}

transaction (minterController: UInt64 ) {
    prepare(masterMinter: AuthAccount) {
        let mm = masterMinter.borrow<&FiatToken.MasterMinter>(from: FiatToken.MasterMinterStoragePath)
            ?? panic ("no masterminter resource avaialble");

        mm.removeMinterController(minterController: minterController);
    }
    post {
        FiatToken.getManagedMinter(resourceId: minterController) == nil : "minterController not removed"
    }
}
