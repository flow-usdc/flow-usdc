import FiatToken from 0x{{.FiatToken}}

pub fun main(resourceName: String): PublicPath {
    switch resourceName {
        case "MasterMinter":
            return FiatToken.MasterMinterPubSigner
        case "Minter":
            return FiatToken.MinterPubSigner
    }
    return FiatToken.MasterMinterPubSigner
}
