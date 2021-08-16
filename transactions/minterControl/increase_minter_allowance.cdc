// MinterController uses this to increase minter allowance 

import FiatToken from 0x{{.FiatToken}}
import FiatTokenInterface from 0x{{.FiatTokenInterface}}

transaction (amount: UFix64) {
    prepare(minterController: AuthAccount) {
        let mc = minterController.borrow<&FiatToken.MinterController>(from: FiatToken.MinterControllerStoragePath) 
            ?? panic ("no minter controller resource avaialble");

        mc.increaseMinterAllowance(increment: amount);
    }
}
