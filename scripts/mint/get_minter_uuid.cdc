import FiatToken from 0x{{.FiatToken}}
import FiatTokenInterface from 0x{{.FiatTokenInterface}}


pub fun main(account: Address): UInt64 {
    let acct = getAccount(account)
    let minterRef = acct.getCapability(FiatToken.MinterUUIDPubPath)
        .borrow<&FiatToken.Minter{FiatToken.ResourceId}>()
        ?? panic("Could not borrow Get UUID reference to the Minter")

    return minterRef.UUID()
}
