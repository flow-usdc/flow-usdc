// This script uses the resources PubSigner Public path to use the UUID function for uuid
//
// Alternatively, if the resource owner do not want to link PubSigner path, they can simply
// link the ResourceId interfaces and this script should then use the <Resource>UUIDPubPath, i.e. VaultUUIDPubPath

import FiatToken from 0x{{.FiatToken}}
import OnChainMultiSig from 0x{{.OnChainMultiSig}}

pub fun main(resourceAddr: Address, resourceName: String): UInt64 {
    let resourceAcct = getAccount(resourceAddr)
    var resourcePubPath: PublicPath = FiatToken.VaultUUIDPubPath

    switch resourceName {
        case "Vault":
            resourcePubPath = FiatToken.VaultUUIDPubPath
        case "Minter":
            resourcePubPath = FiatToken.MinterUUIDPubPath
        case "MinterController":
            resourcePubPath = FiatToken.MinterControllerUUIDPubPath
        case "MasterMinter":
            resourcePubPath = FiatToken.MasterMinterUUIDPubPath
        case "Pauser":
            resourcePubPath = FiatToken.PauserUUIDPubPath
        case "Blocklister":
            resourcePubPath = FiatToken.BlocklisterUUIDPubPath
        case "Admin":
            resourcePubPath = FiatToken.AdminUUIDPubPath
        case "Owner":
            resourcePubPath = FiatToken.OwnerUUIDPubPath
        default:
            panic ("Resource not supported")
    }

    let ref = resourceAcct.getCapability(resourcePubPath)
        .borrow<&{FiatToken.ResourceId}>()
        ?? panic("Could not borrow Get UUID reference to the Resource")

    return ref.UUID()
}
