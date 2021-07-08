import USDC from 0x{{.USDCToken}}

pub fun main(uuid: UInt64): UInt64? {
    return USDC.blocklist[uuid]
}
