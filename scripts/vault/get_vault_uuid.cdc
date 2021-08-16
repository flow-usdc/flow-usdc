import FiatToken from 0x{{.FiatToken}}
import FiatTokenInterface from 0x{{.FiatTokenInterface}}


pub fun main(account: Address): UInt64 {
    let acct = getAccount(account)
    let vaultRef = acct.getCapability(FiatToken.VaultUUIDPubPath)
        .borrow<&FiatToken.Vault{FiatTokenInterface.VaultUUID}>()
        ?? panic("Could not borrow Get UUID reference to the Vault")

    return vaultRef.UUID()
}
