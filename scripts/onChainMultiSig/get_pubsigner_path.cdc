import FiatToken from 0x{{.FiatToken}}

pub fun main(resourceName: String): PublicPath {
    switch resourceName {
        case "MasterMinter":
            return FiatToken.MasterMinterPubSigner
        case "Minter":
            return FiatToken.MinterPubSigner
        case "MinterController":
            return FiatToken.MinterControllerPubSigner
    }
    return FiatToken.MasterMinterPubSigner
}
