/// FiatTokenInterface
///
/// THIS CONTRACT IS DEPRECATED
/// It will not be upgraded to Cadence 1.0
/// It can still be used as a reference for developers
/// but should not be copied without modifications

import "FungibleToken"

access(all) contract interface FiatTokenInterface {

    // ===== Token Info =====
    /// The name of the Token
    access(all) let name: String
    /// The current version of this contract
    access(all) var version: String

    // ===== Contract Paths =====
    access(all) let VaultStoragePath: StoragePath
    access(all) let VaultBalancePubPath: PublicPath
    access(all) let VaultUUIDPubPath: PublicPath
    access(all) let VaultReceiverPubPath: PublicPath

    access(all) let BlocklistExecutorStoragePath: StoragePath
    
    access(all) let BlocklisterStoragePath: StoragePath
    access(all) let BlocklisterCapReceiverPubPath: PublicPath
    access(all) let BlocklisterPubSigner: PublicPath

    access(all) let PauseExecutorStoragePath: StoragePath

    access(all) let PauserStoragePath: StoragePath
    access(all) let PauserCapReceiverPubPath: PublicPath
    access(all) let PauserPubSigner: PublicPath

    access(all) let OwnerStoragePath: StoragePath

    access(all) let MasterMinterStoragePath: StoragePath
    access(all) let MasterMinterPubSigner: PublicPath
    access(all) let MasterMinterUUIDPubPath: PublicPath

    access(all) let MinterControllerStoragePath: StoragePath
    access(all) let MinterControllerUUIDPubPath: PublicPath
    access(all) let MinterControllerPubSigner: PublicPath

    access(all) let MinterStoragePath: StoragePath
    access(all) let MinterUUIDPubPath: PublicPath

    // ===== Pause state and events =====
    /// Contract is paused if `paused` is `true`
    /// All transactions must check this value
    /// No transaction, apart from unpaused, can occur when paused
    access(all) var paused: Bool

    /// Paused
    ///
    /// The event that is emitted when the contract is set to be paused 
    access(all) event Paused()

    // Unpaused
    ///
    /// The event that is emitted when the contract is set from paused to unpaused 
    access(all) event Unpaused()

    /// PauserCreated 
    ///
    /// The event that is emitted when a new pauser resource is created
    access(all) event PauserCreated(resourceId: UInt64)

    // ===== Blocklist state and events =====

    /// Dict of all blocklisted
    /// This is managed by the blocklister
    /// Resources such as Vaults and Minters can be blocked
    /// {resourceId: Block Height}
    access(contract) let blocklist: {UInt64: UInt64}

    /// getBlockList
    ///
    /// Returns block when resource is blocklisted, nil otherwise
    access(all) fun getBlocklist(resourceId: UInt64): UInt64?

    /// Blocklisted
    ///
    /// The event that is emitted when new resource has been blocklisted 
    access(all) event Blocklisted(resourceId: UInt64)

    /// Unblocklisted
    ///
    /// The event that is emitted when new resource has been unblocklisted 
    access(all) event Unblocklisted(resourceId: UInt64)

    /// BlocklisterCreated
    ///
    /// The event that is emitted when a new blocklister resource is created
    access(all) event BlocklisterCreated(resourceId: UInt64)


    // ===== Minting states and events =====

    /// Dict of minter controller to their minter
    /// Only one minter per minter controller but each minter may be controller by multiple controllers
    access(contract) let managedMinters: {UInt64: UInt64}

    /// Minting restrictions include allowance, deadline, vault reciever
    /// Dict of all minters and their allowances
    access(contract) let minterAllowances: { UInt64: UFix64}

    /// getManagedMinter
    ///
    /// Returns the minter managed by the minterController, nil if none is managed
    access(all) view fun getManagedMinter(resourceId: UInt64): UInt64?

    /// getMinterAllowance
    ///
    /// Returns the allowanced assigned to the minter, nil if none is assigned
    access(all) view fun getMinterAllowance(resourceId: UInt64): UFix64?
    
    /// MinterCreated
    ///
    /// The event that is emitted when a new minter resource is created
    access(all) event MinterCreated(resourceId: UInt64)

    /// MinterControllerCreated
    ///
    /// The event that is emitted when a new minter controller resource is created
    /// A minter controller manages the restrictions of exactly 1 minter.
    access(all) event MinterControllerCreated(resourceId: UInt64)

    /// Mint
    ///
    /// The event that is emitted when new tokens are minted
    access(all) event Mint(minter: UInt64, amount: UFix64)

    /// Burn
    ///
    /// The event that is emitted when tokens are burnt by minter
    access(all) event Burn(minter: UInt64, amount: UFix64)

    /// MinterConfigured 
    ///
    /// The event that is emitted when minter controller has configured a minter's restrictions 
    access(all) event MinterConfigured(controller: UInt64, minter: UInt64, allowance: UFix64)

    /// MinterRemoved
    ///
    /// The event that is emitted when minter controller has removed the minter 
    access(all) event MinterRemoved(controller: UInt64, minter: UInt64)

    /// ControllerConfigured
    ///
    /// The event that is emitted when master minter has set the mint controller's minter 
    access(all) event ControllerConfigured(controller: UInt64, minter: UInt64)

    /// ControllerRemoved
    ///
    /// The event that is emitted when master minter has removed the mint controller 
    access(all) event ControllerRemoved(controller: UInt64)

    access(all) resource interface Admin {

        // Update contract is experimental - https://docs.onflow.org/cadence/language/contracts/#updating-a-deployed-contract
        access(all) fun upgradeContract(name: String, code: [UInt8], version: String)

        // Updates the admin role to a new address.
        // May only be called by the admin role.
        // https://github.com/centrehq/centre-tokens/blob/master/doc/tokendesign.md#admin
        access(all) fun changeAdmin(to: Address, newPath: PrivatePath)

    }

    /// The master minter is defined in https://github.com/centrehq/centre-tokens/blob/master/doc/tokendesign.md
    ///
    /// The master minter creates minter controller resources to delegate control for minters
    access(all) resource interface MasterMinter {

        /// Function to configure MinterController
        /// This should configure the minter for the controller 
        access(all) fun configureMinterController(minter: UInt64, minterController: UInt64)

        /// Function to remove MinterController
        /// This should remove the capability from the MasterMinter
        access(all) fun removeMinterController(minterController: UInt64)
    }

    /// This is a resource interface to manage minters, delegated from MasterMinter
    access(all) resource interface MinterController {
        /// configureMinter 
        ///
        /// Function that updates existing minter restrictions
        access(all) fun configureMinterAllowance(allowance: UFix64)

        /// increaseMinterAllowance
        ///
        /// Function that increases the existing minter allowance
        access(all) fun increaseMinterAllowance(increment: UFix64)

        /// decreaseMinterAllowance
        ///
        /// Function that decreases the existing minter allowance
        access(all) fun decreaseMinterAllowance(decrement: UFix64)

        /// removeMinter 
        ///
        /// Function that removes Minter from `minterAllowances`
        /// MinterController can still manage the Minter
        access(all) fun removeMinter()
    }

    /// The minter is controlled by at least 1 minter controller
    access(all) resource interface Minter {
        /// mint
        ///
        /// Function to mint supply, allowance must be set by a MinterController
        access(all) fun mint(amount: UFix64): @FungibleToken.Vault

        /// burn
        ///
        /// Fucntion to burn tokens from the input Vault
        access(all) fun burn(vault: @FungibleToken.Vault)
    }

    /// Interface required for blocklisting a resource 
    access(all) resource interface Blocklister {
        /// blocklist
        ///
        /// Blocklister with provided capability use this function to blocklist a resource
        access(all) fun blocklist(resourceId: UInt64)

        /// unblocklist
        ///
        /// Blocklister with provided capability use this function to unblocklist a resource
        access(all) fun unblocklist(resourceId: UInt64)
    }

    /// Interface required for pausing the contract
    access(all) resource interface Pauser {
        /// pause
        ///
        /// Pauser with provided capability use this function to pause a contract
        access(all) fun pause()

        /// unpause
        ///
        /// Pauser with provided capability use this function to unpause a contract
        access(all) fun unpause()
    }

    /// Interface for another vault to receive an allowance
    /// Should be linked to the public domain
    access(all) resource interface Allowance {
        /// allowance
        ///
        /// Find the allowance for a Vault in another Vault
        access(all) fun allowance(resourceId: UInt64): UFix64?

        /// withdrawAllowance
        ///
        /// Anyone can call this for a receiving Vault, succeeds if allowance is above amount
        access(all) fun withdrawAllowance(recvAddr: Address, amount: UFix64)
    }
}
