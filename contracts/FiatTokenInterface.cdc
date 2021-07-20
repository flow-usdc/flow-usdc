import FungibleToken from "./FungibleToken.cdc"

pub contract interface FiatTokenInterface {

    // ===== Token Info =====
    pub let name: String;

    // ===== Contract Paths =====
    pub let VaultStoragePath: StoragePath;
    pub let VaultBalancePubPath: PublicPath;
    pub let VaultUUIDPubPath: PublicPath;
    pub let VaultAllowancePubPath: PublicPath;
    pub let VaultReceiverPubPath: PublicPath;

    pub let BlocklistExecutorStoragePath: StoragePath;
    pub let BlocklistExecutorPrivPath: PrivatePath;
    
    pub let BlocklisterStoragePath: StoragePath;
    pub let BlocklisterCapReceiverPubPath: PublicPath;

    pub let PauseExecutorStoragePath: StoragePath;
    pub let PauseExecutorPrivPath: PrivatePath;

    pub let PauserStoragePath: StoragePath;
    pub let PauserCapReceiverPubPath: PublicPath;

    pub let OwnerStoragePath: StoragePath;
    pub let OwnerPrivPath: PrivatePath;

    pub let MasterMinterStoragePath: StoragePath;
    pub let MasterMinterPrivPath: PrivatePath;

    pub let MinterControllerStoragePath: StoragePath;
    pub let MinterControllerUUIDPubPath: PublicPath;

    pub let MinterStoragePath: StoragePath;
    pub let MinterUUIDPubPath: PublicPath;
    
    // ===== Pause state and events =====
    /// Contract is paused if `paused` is `true`
    /// All transactions must check this value
    /// No transaction, apart from unpaused, can occur when paused
    pub var paused: Bool;
    /// Paused
    ///
    /// The event that is emitted when the contract is set to be paused 
    pub event Paused();
    // Unpaused
    ///
    /// The event that is emitted when the contract is set from paused to unpaused 
    pub event Unpaused();
    /// PauserCreated 
    ///
    /// The event that is emitted when a new pauser resource is created
    pub event PauserCreated(resourceId: UInt64)

    // ===== Blocklist state and events =====

    /// Dict of all blocklisted
    /// This is managed by the blocklister
    /// Resources such as Vaults and Minters can be blocked
    /// {resourceId: Block Height}
    pub var blocklist: {UInt64: UInt64};
    /// Blocklisted
    ///
    /// The event that is emitted when new resource has been blocklisted 
    pub event Blocklisted(resourceId: UInt64);
    /// Unblocklisted
    ///
    /// The event that is emitted when new resource has been unblocklisted 
    pub event Unblocklisted(resourceId: UInt64);
    /// BlocklisterCreated
    ///
    /// The event that is emitted when a new blocklister resource is created
    pub event BlocklisterCreated(resourceId: UInt64)


    // ===== Minting states and events =====

    /// Dict of minter controller to their minter
    /// Only one minter per minter controller but each minter may be controller by multiple controllers
    pub var managedMinters: {UInt64: UInt64}
    /// Minting restrictions include allowance, deadline, vault reciever
    /// Dict of all minters and their allowances
    pub var minterAllowances: { UInt64: UFix64};
    /// Dict of all minters and their deadlines in terms of block height 
    pub var minterDeadlines: { UInt64: UInt64};
    /// Dict of all minters and their restricted vault reciever
    pub var minterReceivers: { UInt64: UInt64};
    /// MinterCreated
    ///
    /// The event that is emitted when a new minter resource is created
    pub event MinterCreated(resourceId: UInt64);
    /// MinterControllerCreated
    ///
    /// The event that is emitted when a new minter controller resource is created
    /// A minter controller manages the restrictions of exactly 1 minter.
    pub event MinterControllerCreated(resourceId: UInt64);
    /// Mint
    ///
    /// The event that is emitted when new tokens are minted
    pub event Mint(minter: UInt64, amount: UFix64);
    /// Burn
    ///
    /// The event that is emitted when tokens are burnt by minter
    pub event Burn(minter: UInt64, amount: UFix64);
    /// MinterConfigured 
    ///
    /// The event that is emitted when minter controller has configured a minter's restrictions 
    pub event MinterConfigured(controller: UInt64, minter: UInt64, allowance: UFix64);
    /// MinterRemoved
    ///
    /// The event that is emitted when minter controller has removed the minter 
    pub event MinterRemoved(controller: UInt64, minter: UInt64);
    /// ControllerConfigured
    ///
    /// The event that is emitted when master minter has set the mint controller's minter 
    pub event ControllerConfigured(controller: UInt64, minter: UInt64);
    /// ControllerRemoved
    ///
    /// The event that is emitted when master minter has removed the mint controller 
    pub event ControllerRemoved(controller: UInt64);


    /// The master minter is defined in https://github.com/centrehq/centre-tokens/blob/master/doc/tokendesign.md
    ///
    /// The master minter creates minter controller resources to delegate control for minters
    pub resource interface MasterMinter {

        /// Function to configure MinterController
        /// This should configure the minter for the controller 
        pub fun configureMinterController(minter: UInt64, minterController: UInt64);

        /// Function to remove MinterController
        /// This should remove the capability from the MasterMinter
        pub fun removeMinterController(minterController: UInt64);
    }

    /// This is a resource interface to manage minters, delegated from MasterMinter
    pub resource interface MinterController {
        /// configureMinter 
        ///
        /// Function that updates existing minter restrictions
        pub fun configureMinterAllowance(allowance: UFix64);
        pub fun increaseMinterAllowance(increment: UFix64);
        pub fun decreaseMinterAllowance(decrement: UFix64);
        pub fun removeMinter();
    }

    /// The minter is controlled by at least 1 minter controller
    pub resource interface Minter {
        pub fun mint(amount: UFix64): @FungibleToken.Vault;
        pub fun burn(vault: @FungibleToken.Vault);
    }

    /// Interface required for blocklisting a resource 
    pub resource interface Blocklister {
        pub fun blocklist(resourceId: UInt64);
        pub fun unblocklist(resourceId: UInt64);
    }

    /// Interface required for pausing the contract
    pub resource interface Pauser {
        // Note: this only sets the state of the pause of the contract
        pub fun pause(); 
        pub fun unpause();
    }

    pub resource interface VaultUUID {
        pub fun UUID(): UInt64;
    }
    
    /// Interface for another vault to receive an allowance
    /// Should be linked to the public domain
    pub resource interface Allowance {
        pub var allowed: {UInt64: UFix64};
        pub fun allowance(resourceId: UInt64): UFix64?;
        pub fun withdrawAllowance(recvAddr: Address, amount: UFix64);
    }
}
