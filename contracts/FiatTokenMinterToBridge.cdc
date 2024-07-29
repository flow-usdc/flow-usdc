import "FiatToken"
import "FlowEVMBridgeConfig"

/// This contract acts as a way to create a FiatToken.MinterResource
/// and send it directly to the Flow/EVM bridge trustlessly
/// It will be deployed after the Cadence 1.0 upgrades are complete

access(all) contract FiatTokenMinterToBridge {

    /// Sends the FiatToken Minter to the Flow/EVM bridge
    /// without giving any account access to the minter
    /// before it is safely in the decentralized bridge
    access(self) fun sendMinterToBridge(_ bridgeAddress: Address) {
        let minter <- FiatToken.createMinter()
        // borrow a reference to the bridge's configuration admin resource from public Capability
        let bridgeAdmin = getAccount(bridgeAddress).capabilities.borrow<&FlowEVMBridgeConfig.Admin>(
                FlowEVMBridgeConfig.adminPublicPath
            ) ?? panic("FlowEVMBridgeConfig.Admin could not be referenced from ".concat(bridgeAddress.toString()))
            
        // sets the FiatToken as the minter resource for all FiatToken bridge requests
        // prior to transferring the Minter, a TokenHandler will be set for FiatToken during the bridge's initial
        // configuration, setting the stage for this minter to be sent.
        bridgeAdmin.setTokenHandlerMinter(targetType: Type<@FiatToken.Vault>(), minter: <-minter)
    }
    
    init(bridgeAddress: Address) {
        // send the minter to the bridge
        self.sendMinterToBridge(bridgeAddress)
    }
}