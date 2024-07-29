import "EVM"

import "FlowToken"

import "FlowEVMBridgeHandlerInterfaces"

/// This contract is used to store configuration information shared by FlowEVMBridge contracts
///
access(all)
contract FlowEVMBridgeConfig {

    /******************
        Entitlements
    *******************/

    access(all) entitlement Gas
    access(all) entitlement Fee
    access(all) entitlement Pause

    /*************
        Fields
    **************/

    /// Amount of FLOW paid to onboard a Type or EVMAddress to the bridge
    access(all)
    var onboardFee: UFix64
    /// Flat rate fee for all bridge requests
    access(all)
    var baseFee: UFix64
    /// Default ERC20.decimals() value
    access(all)
    let defaultDecimals: UInt8
    /// The gas limit for all EVM calls related to bridge operations
    access(all)
    var gasLimit: UInt64
    /// Flag enabling pausing of bridge operations
    access(self)
    var paused: Bool
    /// Mapping of Type to its associated EVMAddress. The contained struct values also store the operational status of
    /// the association, allowing for pausing of operations by Type
    access(self) let registeredTypes: {Type: TypeEVMAssociation}
    /// Reverse mapping of registeredTypes. Note the EVMAddress is stored as a hex string since the EVMAddress type
    /// as of contract development is not a hashable or equatable type and making it so is not supported by Cadence
    access(self)
    let evmAddressHexToType: {String: Type}
    /// Mapping of Type to its associated EVMAddress as relevant to the bridge
    access(self)
    let typeToTokenHandlers: @{Type: {FlowEVMBridgeHandlerInterfaces.TokenHandler}}

    /********************
        Path Constants
    *********************/

    /// StoragePath where bridge Cadence Owned Account is stored
    access(all)
    let coaStoragePath: StoragePath
    /// StoragePath where bridge config Admin is stored
    access(all)
    let adminStoragePath: StoragePath
    /// PublicPath where a public Capability on the bridge config Admin is exposed
    access(all)
    let adminPublicPath: PublicPath
    /// StoragePath to store the Provider capability used as a bridge fee Provider
    access(all)
    let providerCapabilityStoragePath: StoragePath

    /*************
        Events
    **************/

    /// Emitted whenever the onboarding fee is updated
    ///
    access(all)
    event BridgeFeeUpdated(old: UFix64, new: UFix64, isOnboarding: Bool)
    /// Emitted whenever a TokenHandler is configured
    ///
    access(all)
    event HandlerConfigured(targetType: String, targetEVMAddress: String?, isEnabled: Bool)
    /// Emitted whenever the bridge is paused or unpaused globally - true for paused, false for unpaused
    ///
    access(all)
    event BridgePauseStatusUpdated(paused: Bool)
    /// Emitted whenever a specific asset is paused or unpaused - true for paused, false for unpaused
    ///
    access(all)
    event AssetPauseStatusUpdated(paused: Bool, type: String, evmAddress: String)
    /// Emitted whenever an association is updated
    ///
    access(all)
    event AssociationUpdated(type: String, evmAddress: String)

    /*************
        Getters
     *************/

    /// Returns whether all bridge operations are currently paused or active
    ///
    access(all)
    view fun isPaused(): Bool {
        return self.paused
    }

    /// Returns whether operations for a given Type are paused. A return value of nil indicates the Type is not yet
    /// onboarded to the bridge.
    ///
    access(all)
    view fun isTypePaused(_ type: Type): Bool? {
        if !self.typeHasTokenHandler(type) {
            // Most all assets will fall into this block - check if the asset is onboarded and paused
            return self.registeredTypes[type]?.isPaused ?? nil
        }
        // If the asset has a TokenHandler, return true if either the Handler is paused or the type is paused
        return self.borrowTokenHandler(type)!.isEnabled() == false || self.registeredTypes[type]?.isPaused == true
    }

    /// Retrieves the EVMAddress associated with a given Type if it has been onboarded to the bridge
    ///
    access(all)
    view fun getEVMAddressAssociated(with type: Type): EVM.EVMAddress? {
        return self.registeredTypes[type]?.evmAddress
    }

    /// Retrieves the type associated with a given EVMAddress if it has been onboarded to the bridge
    ///
    access(all)
    view fun getTypeAssociated(with evmAddress: EVM.EVMAddress): Type? {
        let evmAddressHex = evmAddress.toString()
        return self.evmAddressHexToType[evmAddressHex]
    }

    /****************************
        Bridge Account Methods
     ****************************/

    /// Enables bridge contracts to add new associations between types and EVM addresses
    ///
    access(account)
    fun associateType(_ type: Type, with evmAddress: EVM.EVMAddress) {
        pre {
            self.getEVMAddressAssociated(with: type) == nil: "Type already associated with an EVMAddress"
            self.getTypeAssociated(with: evmAddress) == nil: "EVMAddress already associated with a Type"
        }
        self.registeredTypes[type] = TypeEVMAssociation(associated: evmAddress)
        let evmAddressHex = evmAddress.toString()
        self.evmAddressHexToType[evmAddressHex] = type

        emit AssociationUpdated(type: type.identifier, evmAddress: evmAddressHex)
    }

    /// Returns whether the given Type has a TokenHandler configured
    ///
    access(account)
    view fun typeHasTokenHandler(_ type: Type): Bool {
        return self.typeToTokenHandlers[type] != nil
    }

    /// Returns whether the given EVMAddress has a TokenHandler configured
    ///
    access(account)
    view fun evmAddressHasTokenHandler(_ evmAddress: EVM.EVMAddress): Bool {
        let associatedType = self.getTypeAssociated(with: evmAddress)
        return associatedType != nil ? self.typeHasTokenHandler(associatedType!) : false
    }

    /// Adds a TokenHandler to the bridge configuration
    ///
    access(account)
    fun addTokenHandler(_ handler: @{FlowEVMBridgeHandlerInterfaces.TokenHandler}) {
        pre {
            handler.getTargetType() != nil: "Cannot configure Handler without a target Cadence Type set"
            self.getEVMAddressAssociated(with: handler.getTargetType()!) == nil:
                "Cannot configure Handler for Type that has already been onboarded to the bridge"
            self.borrowTokenHandler(handler.getTargetType()!) == nil:
                "Cannot configure Handler for Type that already has a Handler configured"
        }
        let type = handler.getTargetType()!
        var targetEVMAddressHex: String? = nil
        if let targetEVMAddress = handler.getTargetEVMAddress() {
            targetEVMAddressHex = targetEVMAddress.toString()

            let associatedType = self.getTypeAssociated(with: targetEVMAddress)
            assert(
                associatedType == nil,
                message: "Handler target EVMAddress is already associated with a different Type"
            )
            self.associateType(type, with: targetEVMAddress)
        }

        emit HandlerConfigured(
            targetType: type.identifier,
            targetEVMAddress: targetEVMAddressHex,
            isEnabled: handler.isEnabled()
        )

        self.typeToTokenHandlers[type] <-! handler
    }

    /// Returns an unentitled reference to the TokenHandler associated with the given Type
    ///
    access(account)
    view fun borrowTokenHandler(
        _ type: Type
    ): &{FlowEVMBridgeHandlerInterfaces.TokenHandler}? {
        return &self.typeToTokenHandlers[type]
    }

    /// Returns an entitled reference to the TokenHandler associated with the given Type
    ///
    access(self)
    view fun borrowTokenHandlerAdmin(
        _ type: Type
    ): auth(FlowEVMBridgeHandlerInterfaces.Admin) &{FlowEVMBridgeHandlerInterfaces.TokenHandler}? {
        return &self.typeToTokenHandlers[type]
    }

    /*****************
        Constructs
     *****************/

    /// Entry in the registeredTypes mapping, associating a Type with an EVMAddress and its operational status. Since
    /// the registeredTypes mapping is indexed on Type, this struct does not additionally store the Type to reduce
    /// redundant storage.
    ///
    access(all) struct TypeEVMAssociation {
        /// The EVMAddress associated with the Type
        access(all) let evmAddress: EVM.EVMAddress
        /// Flag indicating whether operations for the associated Type are paused
        access(all) var isPaused: Bool

        init(associated evmAddress: EVM.EVMAddress) {
            self.evmAddress = evmAddress
            self.isPaused = false
        }

        /// Pauses operations for this association
        ///
        access(contract) fun pause() {
            self.isPaused = true
        }

        /// Unpauses operations for this association
        ///
        access(contract) fun unpause() {
            self.isPaused = false
        }
    }

    /*****************
        Config Admin
     *****************/

    /// Admin resource enables updates to the bridge fees
    ///
    access(all)
    resource Admin {

        /// Sets the TokenMinter for the given Type. If a TokenHandler does not exist for the given Type, the operation
        /// reverts. The provided minter must be of the expected type for the TokenHandler and the handler cannot have
        /// a minter already set.
        ///
        /// @param targetType: Cadence type indexing the relevant TokenHandler
        /// @param minter: TokenMinter minter to set for the TokenHandler
        ///
        access(all)
        fun setTokenHandlerMinter(targetType: Type, minter: @{FlowEVMBridgeHandlerInterfaces.TokenMinter}) {
            pre {
                FlowEVMBridgeConfig.typeHasTokenHandler(targetType):
                    "Cannot set minter for Type that does not have a TokenHandler configured"
                FlowEVMBridgeConfig.borrowTokenHandlerAdmin(targetType) != nil:
                    "No handler found for target Type"
                FlowEVMBridgeConfig.borrowTokenHandlerAdmin(targetType)!.getExpectedMinterType() == minter.getType():
                    "Invalid minter type"
            }
            FlowEVMBridgeConfig.borrowTokenHandlerAdmin(targetType)!.setMinter(<-minter)
        }

        /// Sets the gas limit for all EVM calls related to bridge operations
        ///
        /// @param lim the new gas limit
        ///
        access(Gas)
        fun setGasLimit(_ limit: UInt64) {
            FlowEVMBridgeConfig.gasLimit = limit
        }

        /// Updates the onboarding fee
        ///
        /// @param new: UFix64 - new onboarding fee
        ///
        /// @emits BridgeFeeUpdated with the old and new rates and isOnboarding set to true
        ///
        access(Fee)
        fun updateOnboardingFee(_ new: UFix64) {
            emit BridgeFeeUpdated(old: FlowEVMBridgeConfig.onboardFee, new: new, isOnboarding: true)
            FlowEVMBridgeConfig.onboardFee = new
        }

        /// Updates the base fee
        ///
        /// @param new: UFix64 - new base fee
        ///
        /// @emits BridgeFeeUpdated with the old and new rates and isOnboarding set to false
        ///
        access(Fee)
        fun updateBaseFee(_ new: UFix64) {
            emit BridgeFeeUpdated(old: FlowEVMBridgeConfig.baseFee, new: new, isOnboarding: false)
            FlowEVMBridgeConfig.baseFee = new
        }

        /// Pauses the bridge, preventing all bridge operations
        ///
        access(Pause)
        fun pauseBridge() {
            if FlowEVMBridgeConfig.isPaused() {
                return
            }
            FlowEVMBridgeConfig.paused = true
            emit BridgePauseStatusUpdated(paused: true)
        }

        /// Unpauses the bridge, allowing bridge operations to resume
        ///
        access(Pause)
        fun unpauseBridge() {
            if !FlowEVMBridgeConfig.isPaused() {
                return
            }
            FlowEVMBridgeConfig.paused = false
            emit BridgePauseStatusUpdated(paused: false)
        }

        /// Pauses all operations for a given asset type
        ///
        access(Pause)
        fun pauseType(_ type: Type) {
            let association = &FlowEVMBridgeConfig.registeredTypes[type] as &TypeEVMAssociation?
                ?? panic("Type not associated with an EVM Address")

            if association.isPaused {
                return
            }

            association.pause()

            let evmAddress = association.evmAddress.toString()
            emit AssetPauseStatusUpdated(paused: true, type: type.identifier, evmAddress: evmAddress)
        }

        /// Unpauses all operations for a given asset type
        ///
        access(Pause)
        fun unpauseType(_ type: Type) {
            let association = &FlowEVMBridgeConfig.registeredTypes[type] as &TypeEVMAssociation?
                ?? panic("Type not associated with an EVM Address")

            if !association.isPaused {
                return
            }

            association.unpause()
            let evmAddress = association.evmAddress.toString()
            emit AssetPauseStatusUpdated(paused: false, type: type.identifier, evmAddress: evmAddress)
        }

        /// Sets the target EVM contract address on the handler for a given Type, associating the Cadence type with the
        /// provided EVM address. If a TokenHandler does not exist for the given Type, the operation reverts.
        ///
        /// @param targetType: Cadence type to associate with the target EVM address
        /// @param targetEVMAddress: target EVM address to associate with the Cadence type
        ///
        /// @emits HandlerConfigured with the target Type, target EVM address, and whether the handler is enabled
        ///
        access(FlowEVMBridgeHandlerInterfaces.Admin)
        fun setHandlerTargetEVMAddress(targetType: Type, targetEVMAddress: EVM.EVMAddress) {
            pre {
                FlowEVMBridgeConfig.getEVMAddressAssociated(with: targetType) == nil:
                    "Type already associated with an EVM Address"
                FlowEVMBridgeConfig.getTypeAssociated(with: targetEVMAddress) == nil:
                    "EVM Address already associated with another Type"
            }
            let handler = FlowEVMBridgeConfig.borrowTokenHandlerAdmin(targetType)
                ?? panic("No handler found for target Type")
            handler.setTargetEVMAddress(targetEVMAddress)

            // Get the EVM address currently associated with the target Type. If the association does not exist or the
            // EVM address is different, update the association
            FlowEVMBridgeConfig.associateType(targetType, with: targetEVMAddress)
            assert(
                FlowEVMBridgeConfig.getEVMAddressAssociated(with: targetType)!.equals(targetEVMAddress),
                message: "Problem associating target Type and target EVM Address"
            )

            emit HandlerConfigured(
                targetType: targetType.identifier,
                targetEVMAddress: targetEVMAddress.toString(),
                isEnabled: handler.isEnabled()
            )
        }

        /// Enables the TokenHandler for the given Type. If a TokenHandler does not exist for the given Type, the
        /// operation reverts.
        ///
        /// @param targetType: Cadence type indexing the relevant TokenHandler
        ///
        /// @emits HandlerConfigured with the target Type, target EVM address, and whether the handler is enabled
        ///
        access(FlowEVMBridgeHandlerInterfaces.Admin)
        fun enableHandler(targetType: Type) {
            let handler = FlowEVMBridgeConfig.borrowTokenHandlerAdmin(targetType)
                ?? panic("No handler found for target Type")
            handler.enableBridging()

            let targetEVMAddressHex = handler.getTargetEVMAddress()?.toString()
                ?? panic("Handler cannot be enabled without a target EVM Address")

            emit HandlerConfigured(
                targetType: handler.getTargetType()!.identifier,
                targetEVMAddress: targetEVMAddressHex,
                isEnabled: handler.isEnabled()
            )
        }
    }

    init() {
        self.onboardFee = 0.0
        self.baseFee = 0.0
        self.defaultDecimals = 18
        self.gasLimit = 15_000_000
        self.paused = false

        // Although $FLOW does not have ERC20 address, we associate the the Vault with the EVM address from which
        // EVM transfers originate
        // See FLIP #223 - https://github.com/onflow/flips/pull/225
        let flowOriginationAddress = EVM.EVMAddress(
                bytes: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0]
            )
        let flowVaultType = Type<@FlowToken.Vault>()
        let flowOriginationAddressHex = flowOriginationAddress.toString()
        self.registeredTypes = { flowVaultType: TypeEVMAssociation(associated: flowOriginationAddress) }
        self.evmAddressHexToType = { flowOriginationAddressHex: flowVaultType }

        self.typeToTokenHandlers <- {}

        self.adminStoragePath = /storage/flowEVMBridgeConfigAdmin
        self.adminPublicPath = /public/flowEVMBridgeConfigAdmin
        self.coaStoragePath = /storage/evm
        self.providerCapabilityStoragePath = /storage/bridgeFlowVaultProvider

        // Create & save Admin, issuing a public unentitled Admin Capability
        self.account.storage.save(<-create Admin(), to: self.adminStoragePath)
        let adminCap = self.account.capabilities.storage.issue<&Admin>(self.adminStoragePath)
        self.account.capabilities.publish(adminCap, at: self.adminPublicPath)
    }
}