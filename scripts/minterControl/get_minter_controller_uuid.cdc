import FiatToken from 0x{{.FiatToken}}
import FiatTokenInterface from 0x{{.FiatTokenInterface}}


pub fun main(account: Address): UInt64 {
    let acct = getAccount(account)
    let minterControllerRef = acct.getCapability(FiatToken.MinterControllerUUIDPubPath)
        .borrow<&FiatToken.MinterController{FiatToken.ResourceId}>()
        ?? panic("Could not borrow Get UUID reference to the minterController")

    return minterControllerRef.UUID()
}
