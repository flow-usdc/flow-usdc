import FiatToken from 0x{{.FiatToken}}

pub fun main(uuid: UInt64): UFix64 {
    return FiatToken.getMinterAllowance(resourceId: uuid)!
}
