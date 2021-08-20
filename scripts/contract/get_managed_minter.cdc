import FiatToken from 0x{{.FiatToken}}

pub fun main(uuid: UInt64): UInt64? {
    return FiatToken.getManagedMinter(resourceId: uuid)
}
