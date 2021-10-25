// This gets the pubsigner path for different resources
import FiatToken from 0x{{.FiatToken}}

pub fun main(resourceName: String): PublicPath {
    switch resourceName {
        case "MasterMinter":
            return FiatToken.MasterMinterPubSigner
        case "Minter":
            return FiatToken.MinterPubSigner
        case "MinterController":
            return FiatToken.MinterControllerPubSigner
        case "Vault":
            return FiatToken.VaultPubSigner
        case "Pauser":
            return FiatToken.PauserPubSigner
        case "Blocklister":
            return FiatToken.BlocklisterPubSigner
        case "Admin":
            return FiatToken.AdminPubSigner
        case "Owner":
            return FiatToken.OwnerPubSigner
        default:
            panic("Resource not supported")
    }
    return FiatToken.VaultPubSigner
}
