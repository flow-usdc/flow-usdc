// MinterController uses this to configure minter allowance 
// It succeeds of MinterController has assigned Minter from MasterMinter

import FiatToken from 0x{{.FiatToken}}

transaction (amount: UFix64) {
    prepare(minterController: AuthAccount) {
        let mc = minterController.borrow<&FiatToken.MinterController>(from: FiatToken.MinterControllerStoragePath)
            ?? panic ("no minter controller resource avaialble");

        mc.configureMinterAllowance(allowance: amount);
    }
}
