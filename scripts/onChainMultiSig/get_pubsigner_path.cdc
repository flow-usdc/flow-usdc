// This gets the publi signer path for different resources
import "FiatToken"

access(all) fun main(resourceName: String): PublicPath {
    switch resourceName {
        case "MasterMinter":
            return FiatToken.MasterMinterPubSigner
        case "MinterController":
            return FiatToken.MinterControllerPubSigner
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
    return FiatToken.OwnerPubSigner
}
