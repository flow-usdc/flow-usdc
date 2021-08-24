import FiatToken from 0x{{.FiatToken}}
import OnChainMultiSig from 0x{{.OnChainMultiSig}}

pub fun main(resourceAddr: Address, resourceName: String): UInt64 {
    let resourceAcct = getAccount(resourceAddr)
    var resourcePubPath: PublicPath = FiatToken.VaultPubSigner

    switch resourceName {
        case "Vault":
            resourcePubPath = FiatToken.VaultPubSigner
        case "Minter":
            resourcePubPath = FiatToken.MinterPubSigner
        case "MinterController":
            resourcePubPath = FiatToken.MinterControllerPubSigner
        case "MasterMinter":
            resourcePubPath = FiatToken.MasterMinterPubSigner
        case "Pauser":
            resourcePubPath = FiatToken.PauserPubSigner
        case "Blocklister":
            resourcePubPath = FiatToken.BlocklisterPubSigner
        default:
            panic ("Resource not supported")
    }

    let ref = resourceAcct.getCapability(resourcePubPath)
        .borrow<&{OnChainMultiSig.PublicSigner}>()
        ?? panic("Could not borrow Get UUID reference to the Resource")

    return ref.UUID()
}
