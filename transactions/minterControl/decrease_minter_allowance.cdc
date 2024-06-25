// MinterController uses this to decrease Minter allowance 
// It succeeds of MinterController has assigned Minter from MasterMinter
// and that the Minter previously has been configured and have allowance

import "FiatToken"

transaction (amount: UFix64) {
    prepare(minterController: auth(BorrowValue) &Account) {
        let mc = minterController.storage.borrow<&FiatToken.MinterController>(from: FiatToken.MinterControllerStoragePath) 
            ?? panic ("no minter controller resource avaialble");

        mc.decreaseMinterAllowance(decrement: amount);
    }
}
