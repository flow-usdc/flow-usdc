import FungibleToken from "./FungibleToken.cdc"

pub contract interface USDCInterface {

    // ===== Paths =====
    

    // ===== Pause state and events =====
    pub let OwnerStoragePath: StoragePath;
    pub let PauseExecutorStoragePath: StoragePath;
    pub let BlockListExecutorStoragePath: StoragePath;
    pub let MasterMinterStoragePath: StoragePath;

    pub let OwnerPrivPath: PrivatePath;
    pub let PauseExecutorPrivPath: PrivatePath;
    pub let BlockListExecutorPrivPath: PrivatePath;
    pub let MasterMinterPrivPath: PrivatePath;

    
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
    pub event PauserCreated()

    // ===== Blocklist state and events =====

    /// Dict of all blocklisted
    /// This is managed by the blocklister
    /// Resources such as Vaults and Minters can be blocked
    pub var blocklist: {UInt64: Bool}
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
    pub event BlocklisterCreated()


    // ===== Minting states and events =====

    /// Minting restrictions include allowance, deadline, vault reciever
    /// Dict of all minters and their allowances
    pub var minterAllowances: { UInt64: UFix64};
    /// Dict of all minters and their deadlines in terms of block height 
    pub var minterDeadlines: { UInt64: UInt64};
    /// Dict of all minters and their restricted vault reciever
    pub var minterRecievers: { UInt64: UInt64};
    /// MinterCreated
    ///
    /// The event that is emitted when a new minter resource is created
    pub event MinterCreated(allowedAmount: UFix64);
    /// MinterControllerCreated
    ///
    /// The event that is emitted when a new minter controller resource is created
    /// A minter controller manages the restrictions of exactly 1 minter.
    pub event MinterControllerCreated();
    /// Mint
    ///
    /// The event that is emitted when new tokens are minted
    pub event Mint(minter: UInt64, Amount: UFix64);
    /// Burn
    ///
    /// The event that is emitted when tokens are burnt by minter
    pub event Burn(minter: UInt64, Amount: UFix64);
    /// MinterConfigured 
    ///
    /// The event that is emitted when minter controller has configured a minter's restrictions 
    pub event MinterConfigured(minter: UInt64);
    /// MinterRemoved
    ///
    /// The event that is emitted when minter controller has removed the minter 
    pub event MinterRemoved(minter: UInt64);
    /// MinterAllowanceIncreased
    ///
    /// The event that is emitted when minter controller has increase the minter's allowance
    pub event MinterAllowanceIncreased(minter: UInt64, newAllowance: UFix64);
    /// MinterAllowanceDecreased
    ///
    /// The event that is emitted when minter controller has decrease the minter's allowance
    pub event MinterAllowanceDecreased(minter: UInt64, newAllowance: UFix64);
    /// ControllerConfigured
    ///
    /// The event that is emitted when master minter has set the mint controller's minter 
    pub event ControllerConfigured(controller: UInt64, minter: UInt64);
    /// ControllerRemoved
    ///
    /// The event that is emitted when master minter has removed the mint controller 
    pub event ControllerRemoved(contorller: UInt64);


    /// The master minter is defined in https://github.com/centrehq/centre-tokens/blob/master/doc/tokendesign.md
    ///
    /// The master minter creates minter controller resources to delegate control for minters
    pub resource interface MasterMinter {

        /// Function to configure MinterController
        /// This should configure the minter for the controller 
        pub fun configureMinterController(minter: UInt64, mintController: UInt64);

        /// Function to remove MinterController
        /// This should remove the capability from the MasterMinter
        pub fun removeMinterController(minterController: UInt64);
    }

    /// This is a resource interface to manage minters, delegated from MasterMinter
    pub resource interface MinterController {

        /// The resourceId this MinterController manages
        pub var managedMinter: UInt64?;

        /// configureMinter 
        ///
        /// Function that updates existing minter restrictions
        pub fun configureMinter(allowance: UFix64);
        pub fun incrementMinterAllowance(amount: UFix64);
        pub fun decrementMinterAllowance(amount: UFix64);
        pub fun removeMinter(minter: UInt64);
        
        /// configureManagedMinter 
        ///
        /// Function that updates managedMinter 
        /// only the MasterMinter will have this capability so it is configured by such resource 
        pub fun configureMangedMinter (cap: Capability<&AnyResource{USDCInterface.MasterMinter}>, newManagedMinter: UInt64?) {
            post{self.managedMinter == newManagedMinter: "Must set managed minter to new resourceID"}
        }
    }

    /// The minter is controlled by at least 1 minter controller
    pub resource interface Minter {
        pub fun mint(amount: UFix64): @FungibleToken.Vault;
        pub fun burn(vault: @FungibleToken.Vault);
    }

    /// Interface required for blocklisting a resource 
    pub resource interface BlockLister {
        pub fun blocklist(resourceId: UInt64);
        pub fun unblocklist(resourceId: UInt64);
    }

    /// Interface required for pausing the contract
    pub resource interface Pauser {
        // Note: this only sets the state of the pause of the contract
        pub fun pause(); 
        pub fun unpause();
    }

}
