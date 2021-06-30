import USDC from 0x{{.USDCToken}}

pub fun main(): Bool {
    return USDC.paused
}
