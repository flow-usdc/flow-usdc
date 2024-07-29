import "EVM"

import "FlowEVMBridgeHandlerInterfaces"
import "FlowEVMBridgeConfig"

/// Enables the TokenHandler to fulfill bridge requests.
///
/// @param targetTypeIdentifier: The identifier of the handler's target type.
///
transaction(targetTypeIdentifier: String) {

    let admin: auth(FlowEVMBridgeHandlerInterfaces.Admin) &FlowEVMBridgeConfig.Admin

    prepare(signer: auth(BorrowValue) &Account) {
        self.admin = signer.storage.borrow<auth(FlowEVMBridgeHandlerInterfaces.Admin) &FlowEVMBridgeConfig.Admin>(
                from: FlowEVMBridgeConfig.adminStoragePath
            ) ?? panic("Could not borrow FlowEVMBridgeConfig Admin reference")
    }

    execute {
        let targetType = CompositeType(targetTypeIdentifier)
            ?? panic("Invalid Type identifier provided")
        self.admin.enableHandler(targetType: targetType)
    }
}