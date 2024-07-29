import "EVM"

import "FlowEVMBridgeHandlerInterfaces"
import "FlowEVMBridgeHandlers"

/// Creates a new TokenHandler for a Cadence-native fungible token and configures it in the bridge to handle the target
/// vault type. The minter enabling the handling of tokens as well as the target EVM address must also be set before
// the TokenHandler can be enabled.
///
/// @param vaultIdentifier: The type identifier of the vault to create the TokenHandler for
/// @param minterIdentifier: The type identifier of the TokenMinter implementing resource
///
transaction(vaultIdentifier: String, minterIdentifier: String) {

    let configurator: auth(FlowEVMBridgeHandlerInterfaces.Admin) &FlowEVMBridgeHandlers.HandlerConfigurator

    prepare(signer: auth(BorrowValue, LoadValue) &Account) {
        self.configurator = signer.storage.borrow<auth(FlowEVMBridgeHandlerInterfaces.Admin) &FlowEVMBridgeHandlers.HandlerConfigurator>(
                from: FlowEVMBridgeHandlers.ConfiguratorStoragePath
            ) ?? panic("Missing configurator")
    }

    execute {
        let targetType = CompositeType(vaultIdentifier)
            ?? panic("Invalid vault identifier")
        let minterType = CompositeType(minterIdentifier)
            ?? panic("Invalid minter identifier")
        self.configurator.createTokenHandler(
            handlerType: Type<@FlowEVMBridgeHandlers.CadenceNativeTokenHandler>(),
            targetType: targetType,
            targetEVMAddress: nil,
            expectedMinterType: minterType
        )
    }
}