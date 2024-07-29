import "Burner"
import "FungibleToken"
import "NonFungibleToken"

import "EVM"

import "FlowEVMBridgeHandlerInterfaces"
import "FlowEVMBridgeConfig"
// import "FlowEVMBridgeUtils"

/// FlowEVMBridgeHandlers
///
/// This contract is responsible for defining and configuring bridge handlers for special cased assets.
///
access(all) contract FlowEVMBridgeHandlers {

    /**********************
        Contract Fields
    ***********************/

    /// The storage path for the HandlerConfigurator resource
    access(all) let ConfiguratorStoragePath: StoragePath

    /****************
        Constructs
    *****************/

    /// Handler for bridging Cadence native fungible tokens to EVM. In the event a Cadence project migrates native
    /// support to EVM, this Hander can be configured to facilitate bridging the Cadence tokens to EVM. This Handler
    /// then effectively allows the bridge to treat such tokens as bridge-defined on the Cadence side and EVM-native on
    /// the EVM side minting/burning in Cadence and escrowing in EVM.
    /// In order for this to occur, neither the Cadence token nor the EVM contract can be onboarded to the bridge - in
    /// essence, neither side of the asset can be onboarded to the bridge.
    /// The Handler must be configured in the bridge via the HandlerConfigurator. Once added, the bridge will filter
    /// requests to bridge the token Vault to EVM through this Handler which cannot be enabled until a target EVM
    /// address is set. Once the corresponding EVM contract address is known, it can be set and the Handler. It's also
    /// suggested that the Handler only be enabled once sufficient liquidity has been arranged in bridge escrow on the
    /// EVM side.
    ///
    access(all) resource CadenceNativeTokenHandler : FlowEVMBridgeHandlerInterfaces.TokenHandler {
        /// Flag determining if request handling is enabled
        access(self) var enabled: Bool
        /// The Cadence Type this handler fulfills requests for
        access(self) var targetType: Type
        /// The EVM contract address this handler fulfills requests for. This field is optional in the event the EVM
        /// contract address is not yet known but the Cadence type must still be filtered via Handler to prevent the
        /// type from being onboarded otherwise.
        access(self) var targetEVMAddress: EVM.EVMAddress?
        /// The expected minter type for minting tokens on fulfillment
        access(self) let expectedMinterType: Type
        /// The Minter enabling minting of Cadence tokens on fulfillment from EVM
        access(self) var minter: @{FlowEVMBridgeHandlerInterfaces.TokenMinter}?

        init(targetType: Type, targetEVMAddress: EVM.EVMAddress?, expectedMinterType: Type) {
            pre {
                expectedMinterType.isSubtype(of: Type<@{FlowEVMBridgeHandlerInterfaces.TokenMinter}>()):
                    "Invalid minter type"
            }
            self.enabled = false
            self.targetType = targetType
            self.targetEVMAddress = targetEVMAddress
            self.expectedMinterType = expectedMinterType
            self.minter <- nil
        }

        /* --- HandlerInfo --- */

        /// Returns the enabled status of the handler
        access(all) view fun isEnabled(): Bool {
            return self.enabled
        }

        /// Returns the type of the asset the handler is configured to handle
        access(all) view fun getTargetType(): Type? {
            return self.targetType
        }

        /// Returns the EVM contract address the handler is configured to handle
        access(all) view fun getTargetEVMAddress(): EVM.EVMAddress? {
            return self.targetEVMAddress
        }

        /// Returns the expected minter type for the handler
        access(all) view fun getExpectedMinterType(): Type? {
            return self.expectedMinterType
        }

        /* --- TokenHandler --- */

        /// Fulfill a request to bridge tokens from Cadence to EVM, burning the provided Vault and transferring from
        /// EVM escrow to the named recipient. Assumes any fees are handled by the caller within the bridge contracts
        ///
        /// @param tokens: The Vault containing the tokens to bridge
        /// @param to: The EVM address to transfer the tokens to
        ///
        // access(account)
        // fun fulfillTokensToEVM(
        //     tokens: @{FungibleToken.Vault},
        //     to: EVM.EVMAddress
        // ) {
        //     let evmAddress = self.getTargetEVMAddress()!

        //     // Get values from vault and burn
        //     let amount = tokens.balance
        //     let uintAmount = FlowEVMBridgeUtils.convertCadenceAmountToERC20Amount(amount, erc20Address: evmAddress)

        //     assert(uintAmount > UInt256(0), message: "Amount to bridge must be greater than 0")

        //     Burner.burn(<-tokens)

        //     FlowEVMBridgeUtils.mustTransferERC20(to: to, amount: uintAmount, erc20Address: evmAddress)
        // }

        /// Fulfill a request to bridge tokens from EVM to Cadence, minting the provided amount of tokens in Cadence
        /// and transferring from the named owner to bridge escrow in EVM.
        ///
        /// @param owner: The EVM address of the owner of the tokens. Should also be the caller executing the protected
        ///              transfer call.
        /// @param type: The type of the asset being bridged
        /// @param amount: The amount of tokens to bridge
        ///
        /// @return The minted Vault containing the the requested amount of Cadence tokens
        ///
        // access(account)
        // fun fulfillTokensFromEVM(
        //     owner: EVM.EVMAddress,
        //     type: Type,
        //     amount: UInt256,
        //     protectedTransferCall: fun (): EVM.Result
        // ): @{FungibleToken.Vault} {
        //     let evmAddress = self.getTargetEVMAddress()!

        //     // Convert the amount to a UFix64
        //     let ufixAmount = FlowEVMBridgeUtils.convertERC20AmountToCadenceAmount(
        //             amount,
        //             erc20Address: evmAddress
        //         )
        //     assert(ufixAmount > 0.0, message: "Amount to bridge must be greater than 0")

        //     FlowEVMBridgeUtils.mustEscrowERC20(
        //         owner: owner,
        //         amount: amount,
        //         erc20Address: evmAddress,
        //         protectedTransferCall: protectedTransferCall
        //     )

        //     // After state confirmation, mint the tokens and return
        //     let minter = self.borrowMinter() ?? panic("Minter not set")
        //     let minted <- minter.mint(amount: ufixAmount)
        //     return <-minted
        // }

        /* --- Admin --- */

        /// Sets the target type for the handler
        access(FlowEVMBridgeHandlerInterfaces.Admin)
        fun setTargetType(_ type: Type) {
            self.targetType = type
        }

        /// Sets the target EVM address for the handler
        access(FlowEVMBridgeHandlerInterfaces.Admin)
        fun setTargetEVMAddress(_ address: EVM.EVMAddress) {
            self.targetEVMAddress = address
        }

        /// Sets the target type for the handler
        access(FlowEVMBridgeHandlerInterfaces.Admin)
        fun setMinter(_ minter: @{FlowEVMBridgeHandlerInterfaces.TokenMinter}) {
            pre {
                self.minter == nil: "Minter has already been set"
            }
            self.minter <-! minter
        }

        /// Enables the handler for request handling. The
        access(FlowEVMBridgeHandlerInterfaces.Admin)
        fun enableBridging() {
            pre {
                self.minter != nil: "Cannot enable handler without a minter"
            }
            self.enabled = true
        }

        /* --- Internal --- */

        /// Returns an entitled reference to the encapsulated minter resource
        access(self)
        view fun borrowMinter(): auth(FlowEVMBridgeHandlerInterfaces.Mint) &{FlowEVMBridgeHandlerInterfaces.TokenMinter}? {
            return &self.minter
        }
    }

    /// This resource enables the configuration of Handlers. These Handlers are stored in FlowEVMBridgeConfig from which
    /// further setting and getting can be executed.
    ///
    access(all) resource HandlerConfigurator {
        /// Creates a new Handler and adds it to the bridge configuration
        ///
        /// @param handlerType: The type of handler to create as defined in this contract
        /// @param targetType: The type of the asset the handler will handle.
        /// @param targetEVMAddress: The EVM contract address the handler will handle, can be nil if still unknown
        /// @param expectedMinterType: The Type of the expected minter to be set for the created TokenHandler
        ///
        access(FlowEVMBridgeHandlerInterfaces.Admin)
        fun createTokenHandler(
            handlerType: Type,
            targetType: Type,
            targetEVMAddress: EVM.EVMAddress?,
            expectedMinterType: Type
        ) {
            switch handlerType {
                case Type<@CadenceNativeTokenHandler>():
                    let handler <-create CadenceNativeTokenHandler(
                        targetType: targetType,
                        targetEVMAddress: targetEVMAddress,
                        expectedMinterType: expectedMinterType
                    )
                    FlowEVMBridgeConfig.addTokenHandler(<-handler)
                default:
                    panic("Invalid Handler type requested")
            }
        }
    }

    init() {
        self.ConfiguratorStoragePath = /storage/BridgeHandlerConfigurator
        self.account.storage.save(<-create HandlerConfigurator(), to: self.ConfiguratorStoragePath)
    }
}