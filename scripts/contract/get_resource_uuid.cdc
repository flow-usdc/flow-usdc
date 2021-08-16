import FiatToken from 0x{{.FiatToken}}
import FiatTokenInterface from 0x{{.FiatTokenInterface}}


pub fun main(resourceAddr: Address, resourcePubPath: PublicPath): UInt64 {
    let resourceAcct = getAccount(resourceAddr)
    let ref = resourceAcct.getCapability(resourcePubPath)
        .borrow<&AnyResource{FiatToken.ResourceId}>()
        ?? panic("Could not borrow Get UUID reference to the Resource")

    return ref.UUID()
}
