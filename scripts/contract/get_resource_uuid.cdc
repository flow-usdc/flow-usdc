// This script uses the resources PubSigner Public path to use the UUID function for uuid
//
// Alternatively, if the resource owner do not want to link PubSigner path, they can simply
// link the ResourceId interfaces and this script should then use the <Resource>UUIDPubPath, i.e. VaultUUIDPubPath

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
