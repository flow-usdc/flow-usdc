// MinterController uses this to decrease Minter allowance 
// It succeeds of MinterController has assigned Minter from MasterMinter
// and that the Minter previously has been configured and have allowance

import FiatToken from 0x{{.FiatToken}}

transaction (amount: UFix64) {
    prepare(minterController: AuthAccount) {
        let mc = minterController.borrow<&FiatToken.MinterController>(from: FiatToken.MinterControllerStoragePath) 
            ?? panic ("no minter controller resource avaialble");

        mc.decreaseMinterAllowance(decrement: amount);
    }
}
