// This transaction is a template for withdrawing allowance from a USDC vault

import FungibleToken from 0x{{.FungibleToken}}
import USDC from 0x{{.USDCToken}}
import USDCInterface from 0x{{.USDCInterface}}

transaction(fromAddr: Address, toAddr: Address, amount: UFix64) {
    
    prepare(signer: AuthAccount) {
       
    }

    execute {

        // Get the recipient's public account object
        let fromAcct = getAccount(fromAddr)

        // Get a allowance reference to the fromAcct's vault 
        let allowanceRef = fromAcct.getCapability(/public/UsdcVaultAllowance)
            .borrow<&{USDCInterface.Allowance}>()
            ?? panic("Could not borrow allowance reference")

        allowanceRef.withdrawAllowance(recvAddr: toAddr, amount: amount)
    }
}
