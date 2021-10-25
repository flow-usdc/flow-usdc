// This transaction is a template for withdrawing allowance from a FiatToken vault
// It will be successful iff allowance is set for the toAddr

import FungibleToken from 0x{{.FungibleToken}}
import FiatToken from 0x{{.FiatToken}}

transaction(fromAddr: Address, toAddr: Address, amount: UFix64) {
    prepare(signer: AuthAccount) {
    }
    execute {

        // Get the recipient's public account object
        let fromAcct = getAccount(fromAddr)

        // Get a allowance reference to the fromAcct's vault 
        let allowanceRef = fromAcct.getCapability(FiatToken.VaultAllowancePubPath)
            .borrow<&{FiatToken.Allowance}>()
            ?? panic("Could not borrow allowance reference")

        allowanceRef.withdrawAllowance(recvAddr: toAddr, amount: amount)
    }
}
