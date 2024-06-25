import FungibleToken from "./FungibleToken.cdc"

// This contract was never used on testnet or mainnet,
// so it is not updated to Cadence 1.0

pub contract interface FiatTokenInterface {

    // ===== Token Info =====
    /// The name of the Token
    pub let name: String
    /// The current version of this contract
    pub var version: String

    // ===== Contract Paths =====
    pub let VaultStoragePath: StoragePath
    pub let VaultBalancePubPath: PublicPath
    pub let VaultUUIDPubPath: PublicPath
    pub let VaultReceiverPubPath: PublicPath

    pub let BlocklistExecutorStoragePath: StoragePath
    pub let BlocklistExecutorPrivPath: PrivatePath
    
    pub let BlocklisterStoragePath: StoragePath
    pub let BlocklisterCapReceiverPubPath: PublicPath
    pub let BlocklisterPubSigner: PublicPath

    pub let PauseExecutorStoragePath: StoragePath

    pub let PauserStoragePath: StoragePath
    pub let PauserCapReceiverPubPath: PublicPath
    pub let PauserPubSigner: PublicPath

    pub let OwnerStoragePath: StoragePath
    pub let OwnerPrivPath: PrivatePath

    pub let MasterMinterStoragePath: StoragePath
    pub let MasterMinterPrivPath: PrivatePath
    pub let MasterMinterPubSigner: PublicPath
    pub let MasterMinterUUIDPubPath: PublicPath

    pub let MinterControllerStoragePath: StoragePath
    pub let MinterControllerUUIDPubPath: PublicPath
    pub let MinterControllerPubSigner: PublicPath

    pub let MinterStoragePath: StoragePath
    pub let MinterUUIDPubPath: PublicPath

    // ===== Pause state and events =====
    /// Contract is paused if `paused` is `true`
    /// All transactions must check this value
    /// No transaction, apart from unpaused, can occur when paused
    pub var paused: Bool
    /// Paused
    ///
    /// The event that is emitted when the contract is set to be paused 
    pub event Paused()
    // Unpaused
    ///
    /// The event that is emitted when the contract is set from paused to unpaused 
    pub event Unpaused()
    /// PauserCreated 
    ///
    /// The event that is emitted when a new pauser resource is created
    pub event PauserCreated(resourceId: UInt64)

    // ===== Blocklist state and events =====

    /// Dict of all blocklisted
    /// This is managed by the blocklister
    /// Resources such as Vaults and Minters can be blocked
    /// {resourceId: Block Height}
    access(contract) let blocklist: {UInt64: UInt64}
    /// getBlockList
    ///
    /// Returns block when resource is blocklisted, nil otherwise
    pub fun getBlocklist(resourceId: UInt64): UInt64?
    /// Blocklisted
    ///
    /// The event that is emitted when new resource has been blocklisted 
    pub event Blocklisted(resourceId: UInt64)
    /// Unblocklisted
    ///
    /// The event that is emitted when new resource has been unblocklisted 
    pub event Unblocklisted(resourceId: UInt64)
    /// BlocklisterCreated
    ///
    /// The event that is emitted when a new blocklister resource is created
    pub event BlocklisterCreated(resourceId: UInt64)


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
    pub fun getManagedMinter(resourceId: UInt64): UInt64?
    /// getMinterAllowance
    ///
    /// Returns the allowanced assigned to the minter, nil if none is assigned
    pub fun getMinterAllowance(resourceId: UInt64): UFix64?
    
    /// MinterCreated
    ///
    /// The event that is emitted when a new minter resource is created
    pub event MinterCreated(resourceId: UInt64)
    /// MinterControllerCreated
    ///
    /// The event that is emitted when a new minter controller resource is created
    /// A minter controller manages the restrictions of exactly 1 minter.
    pub event MinterControllerCreated(resourceId: UInt64)
    /// Mint
    ///
    /// The event that is emitted when new tokens are minted
    pub event Mint(minter: UInt64, amount: UFix64)
    /// Burn
    ///
    /// The event that is emitted when tokens are burnt by minter
    pub event Burn(minter: UInt64, amount: UFix64)
    /// MinterConfigured 
    ///
    /// The event that is emitted when minter controller has configured a minter's restrictions 
    pub event MinterConfigured(controller: UInt64, minter: UInt64, allowance: UFix64)
    /// MinterRemoved
    ///
    /// The event that is emitted when minter controller has removed the minter 
    pub event MinterRemoved(controller: UInt64, minter: UInt64)
    /// ControllerConfigured
    ///
    /// The event that is emitted when master minter has set the mint controller's minter 
    pub event ControllerConfigured(controller: UInt64, minter: UInt64)
    /// ControllerRemoved
    ///
    /// The event that is emitted when master minter has removed the mint controller 
    pub event ControllerRemoved(controller: UInt64)

    pub interface resource Admin {

        // Update contract is experimental - https://docs.onflow.org/cadence/language/contracts/#updating-a-deployed-contract
        pub fun upgradeContract(name: String, code: [UInt8], version: String)

        // Updates the admin role to a new address.
        // May only be called by the admin role.
        // https://github.com/centrehq/centre-tokens/blob/master/doc/tokendesign.md#admin
        pub fun changeAdmin(to: Address, newPath: PrivatePath)

    }

    /// The master minter is defined in https://github.com/centrehq/centre-tokens/blob/master/doc/tokendesign.md
    ///
    /// The master minter creates minter controller resources to delegate control for minters
    pub resource interface MasterMinter {

        /// Function to configure MinterController
        /// This should configure the minter for the controller 
        pub fun configureMinterController(minter: UInt64, minterController: UInt64)

        /// Function to remove MinterController
        /// This should remove the capability from the MasterMinter
        pub fun removeMinterController(minterController: UInt64)
    }

    /// This is a resource interface to manage minters, delegated from MasterMinter
    pub resource interface MinterController {
        /// configureMinter 
        ///
        /// Function that updates existing minter restrictions
        pub fun configureMinterAllowance(allowance: UFix64)
        /// increaseMinterAllowance
        ///
        /// Function that increases the existing minter allowance
        pub fun increaseMinterAllowance(increment: UFix64)
        /// decreaseMinterAllowance
        ///
        /// Function that decreases the existing minter allowance
        pub fun decreaseMinterAllowance(decrement: UFix64)
        /// removeMinter 
        ///
        /// Function that removes Minter from `minterAllowances`
        /// MinterController can still manage the Minter
        pub fun removeMinter()
    }

    /// The minter is controlled by at least 1 minter controller
    pub resource interface Minter {
        /// mint
        ///
        /// Function to mint supply, allowance must be set by a MinterController
        pub fun mint(amount: UFix64): @FungibleToken.Vault
        /// burn
        ///
        /// Fucntion to burn tokens from the input Vault
        pub fun burn(vault: @FungibleToken.Vault)
    }

    /// Interface required for blocklisting a resource 
    pub resource interface Blocklister {
        /// blocklist
        ///
        /// Blocklister with provided capability use this function to blocklist a resource
        pub fun blocklist(resourceId: UInt64)
        /// unblocklist
        ///
        /// Blocklister with provided capability use this function to unblocklist a resource
        pub fun unblocklist(resourceId: UInt64)
    }

    /// Interface required for pausing the contract
    pub resource interface Pauser {
        /// pause
        ///
        /// Pauser with provided capability use this function to pause a contract
        pub fun pause() 
        /// unpause
        ///
        /// Pauser with provided capability use this function to unpause a contract
        pub fun unpause()
    }

    /// Interface for another vault to receive an allowance
    /// Should be linked to the public domain
    pub resource interface Allowance {
        /// allowance
        ///
        /// Find the allowance for a Vault in another Vault
        pub fun allowance(resourceId: UInt64): UFix64?
        /// withdrawAllowance
        ///
        /// Anyone can call this for a receiving Vault, succeeds if allowance is above amount
        pub fun withdrawAllowance(recvAddr: Address, amount: UFix64)
    }
}
