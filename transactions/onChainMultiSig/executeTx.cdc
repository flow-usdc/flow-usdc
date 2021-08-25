// Masterminter uses this to configure which minter the minter controller manages

import FiatToken from 0x{{.FiatToken}}
import FiatTokenInterface from 0x{{.FiatTokenInterface}}
import OnChainMultiSig from 0x{{.OnChainMultiSig}}
import FungibleToken from 0x{{.FungibleToken}}

transaction (txIndex: UInt64, resourceAddr: Address, resourcePubSignerPath: PublicPath) {
    let recv: &{FungibleToken.Receiver}
    prepare(oneOfMultiSig: AuthAccount) {
        // Get a reference to the signer's stored vault
        self.recv = oneOfMultiSig.getCapability(FiatToken.VaultReceiverPubPath)!
            .borrow<&{FungibleToken.Receiver}>()
            ?? panic("Unable to borrow receiver reference for recipient")
    }

    execute {
        let resourceAcct = getAccount(resourceAddr)

        let pubSigRef = resourceAcct.getCapability(resourcePubSignerPath)
            .borrow<&{OnChainMultiSig.PublicSigner}>()
            ?? panic("Could not borrow resource pub sig reference")

        let r <- pubSigRef.executeTx(txIndex: txIndex)
        if r != nil {
            // Withdraw tokens from the signer's stored vault
            let vault <- r! as! @FungibleToken.Vault
            self.recv.deposit(from: <- vault)
        } else {
            destroy(r)
        }
    }
}
