import FiatToken from 0x{{.FiatToken}}

pub fun main(resourceName: String): PublicPath {
    switch resourceName {
        case "Vault":
            return FiatToken.VaultUUIDPubPath
        case "Minter":
            return FiatToken.MinterUUIDPubPath
        case "MinterController":
            return FiatToken.MinterControllerUUIDPubPath
        case "MasterMinter":
            return FiatToken.MasterMinterUUIDPubPath
        default:
            panic ("Resource not supported")
    }
    return FiatToken.MasterMinterPubSigner
}
