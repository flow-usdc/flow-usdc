import FungibleToken from 0x{{.FungibleToken}} 
import USDCInterface from 0x{{.USDCInterface}} 

pub contract USDC: USDCInterface, FungibleToken {

    // ===== Pause state and events =====
    pub let OwnerStoragePath: StoragePath;
    pub let PauseExecutorStoragePath: StoragePath;
    pub let BlockListExecutorStoragePath: StoragePath;
    pub let MasterMinterStoragePath: StoragePath;

    pub let OwnerPrivPath: PrivatePath;
    pub let PauseExecutorPrivPath: PrivatePath;
    pub let BlockListExecutorPrivPath: PrivatePath;
    pub let MasterMinterPrivPath: PrivatePath;

    // ===== Pause state and events =====
    
    /// Contract is paused if `paused` is `true`
    /// All transactions must check this value
    /// No transaction, apart from unpaused, can occur when paused
    pub var paused: Bool;
    /// Paused
    ///
    /// The event that is emitted when the contract is set to be paused 
    pub event Paused();
    /// Unpaused
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
    
    // ===== Fungible Token state and events =====

    /// Total supply of usdc in existence
    pub var totalSupply: UFix64;

    /// TokensInitialized
    ///
    /// The event that is emitted when the contract is created
    pub event TokensInitialized(initialSupply: UFix64)

    /// TokensWithdrawn
    ///
    /// The event that is emitted when tokens are withdrawn from a Vault
    pub event TokensWithdrawn(amount: UFix64, from: Address?)

    /// TokensDeposited
    ///
    /// The event that is emitted when tokens are deposited into a Vault
    pub event TokensDeposited(amount: UFix64, to: Address?)
 
    // ===== USDC Resources: =====
    
    pub resource Vault: FungibleToken.Provider, FungibleToken.Receiver, FungibleToken.Balance {

        /// The total balance of this vault
        pub var balance: UFix64

        // initialize the balance at resource creation time
        init(balance: UFix64) {
            self.balance = balance
        }

        pub fun withdraw(amount: UFix64): @FungibleToken.Vault {
            // todo check blocklist and pause state
            self.balance = self.balance - amount
            emit TokensWithdrawn(amount: amount, from: self.owner?.address)
            return <-create Vault(balance: amount)
        }

        pub fun deposit(from: @FungibleToken.Vault) {
            // todo check blocklist and pause state 
            let vault <- from as! @USDC.Vault
            self.balance = self.balance + vault.balance
            emit TokensDeposited(amount: vault.balance, to: self.owner?.address)
            vault.balance = 0.0
            destroy vault 
        }
        destroy() {
            USDC.totalSupply = USDC.totalSupply - self.balance
        }
    }
    
    

    /// The owner is defined in https://github.com/centrehq/centre-tokens/blob/master/doc/tokendesign.md
    ///
    /// Owner can assign all roles
    pub resource Owner {

        pub fun createNewPauseExecutor(): @PauseExecutor{
            // todo set cap
            return <-create PauseExecutor()
        }

        pub fun createNewBlockListExecutor(): @BlockListExecutor{
            // todo set cap
            return <-create BlockListExecutor()
        }

        pub fun createNewMasterMinter(): @MasterMinter{
            // todo set cap
            return <-create MasterMinter()
        }
    }

    /// The master minter is defined in https://github.com/centrehq/centre-tokens/blob/master/doc/tokendesign.md
    ///
    /// The master minter creates minter controller resources to delegate control for minters
    pub resource MasterMinter: USDCInterface.MasterMinter {

     
        /// Function that creates and returns a new minter resource
        /// The controller should be set here too
        pub fun createNewMinter(allowance: UFix64): @Minter {
            // can only create 1
            // update minterAllowance 
            return <- create Minter();
        }

        /// Function to configure MinterController
        /// This should configure the minter for the controller 
        pub fun configureMinterController(minter: UInt64, mintController: UInt64) {
            // todo
        }
        
        /// Function to remove MinterController
        /// This should remove the capability from the MasterMinter
        pub fun removeMinterController(minterController: UInt64){
            // todo
        }
    }

    /// This is a resource to manage minters, delegated from MasterMinter
    pub resource MinterController: USDCInterface.MinterController {

        /// The resourceId this MinterController manages
        pub var managedMinter: UInt64?;

        /// configureMinter 
        ///
        /// Function that updates existing minter restrictions
        pub fun configureMinter(allowance: UFix64) {
            // todo, time, destination vault
        }
        
        pub fun incrementMinterAllowance(amount: UFix64) {
            // todo
        }

        pub fun decrementMinterAllowance(amount: UFix64) {
            // todo
        }
        
        /// removeMinter
        /// 
        /// Function to remove minter
        pub fun removeMinter(minter: UInt64){
            // todo
        }
        
        pub fun configureMangedMinter (cap: Capability<&AnyResource{USDCInterface.MasterMinter}>, newManagedMinter: UInt64?) {
        }
        
        init(){
            self.managedMinter = nil;
        }
    }

    /// The actual minter resource, the resourceId must be added to the minter restrictions lists
    /// for minter to successfully mint / burn within restrictions
    pub resource Minter: USDCInterface.Minter {
        // todo: check allowance
        // todo: check block
        pub fun mint(amount: UFix64): @FungibleToken.Vault{
            return <-create Vault(balance: amount);
        }
        pub fun burn(vault: @FungibleToken.Vault) {
            //todo
            destroy vault;
        }
    }

    /// The blocklist execution resource, account with this resource must share / unlink its capability
    /// with BlockLister to managed permission for block
    pub resource BlockListExecutor: USDCInterface.BlockLister{
        pub fun blocklist(resourceId: UInt64){
            // todo
        };
        pub fun unblocklist(resourceId: UInt64){
            // todo
        };
    }

    /// Delegate blocklister
    pub resource BlockLister {
        access(self) var blocklistcap: Capability<&BlockListExecutor>?;
        pub fun blocklist(resourceId: UInt64){
            // todo
        };
        pub fun unblocklist(resourceId: UInt64){
            // todo
        };
        
        pub fun setCapability(blocklistcap: Capability<&BlockListExecutor>){
            self.blocklistcap = blocklistcap;
        }
        
        init(){
            self.blocklistcap = nil;
        }
    }

    /// The pause execution resource, account with this resource must share / unlink its capability
    /// with Pauser to managed permission for block
    pub resource PauseExecutor: USDCInterface.Pauser {
        // Note: this only sets the state of the pause of the contract
        pub fun pause() { 
            USDC.paused = true;
            emit Paused();
         }
        pub fun unpause() { 
            USDC.paused = false;
            emit Unpaused();
         }
    }

    pub resource interface PauseCapReceiver {
        // Note: this only sets the state of the pause of the contract
        pub fun setPauseCap(pauseCap: Capability<&PauseExecutor>) 
    }

    /// Delegate pauser 
    pub resource Pauser: PauseCapReceiver {
        // This will be a Capability from the PauseExecutor created by the MasterMinter and linked privately.
        // MasterMinter will call setPauseCapability to provide it.
        access(self) var pauseCap:  Capability<&PauseExecutor>?;
        
        // Called by the Account that owns PauseExecutor
        // (since they are the only account that can create such Capability as input arg)
        // This means the PauseExector account "grants" the right to call fn in pauseExecutor
        // 
        // The Account that owns PauseExecutor will be set in init() of the contract
        // and will probably be the MasterMinter/Admin
        pub fun setPauseCap(pauseCap: Capability<&PauseExecutor>) {
            self.pauseCap = pauseCap;
        }

        // Pauser can borrow the pauseCapability, if it exists, and pause and unpause the contract
        pub fun pause(){
            let cap = self.pauseCap!.borrow()!
            cap.pause();
        } 
        
        pub fun unpause(){
            let cap = self.pauseCap!.borrow()!
            cap.unpause();
        }

        init(){
            self.pauseCap = nil;
        }
    }

    // ============ USDC METHODS: ==============

    /// createEmptyVault
    ///
    /// Function that creates a new Vault with a balance of zero
    /// and returns it to the calling context. A user must call this function
    /// and store the returned Vault in their storage in order to allow their
    /// account to be able to receive deposits of this token type.
    ///
    pub fun createEmptyVault(): @Vault {
        return <-create Vault(balance: 0.0)
    }

    pub fun createNewPauser(): @Pauser{
        emit PauserCreated();
        return <-create Pauser()
    }

    pub fun createMinterController(): @MinterController{
        // todo set cap
        return <-create MinterController()
    }

    pub fun createNewBlockLister(): @BlockLister{
        // todo set cap
        return <-create BlockLister()
    }

    init(adminAccount: AuthAccount){
        self.paused = true;
        self.blocklist = {};
        self.totalSupply = 10000.0;
        self.minterAllowances = {};
        self.minterDeadlines = {};
        self.minterRecievers = {};

        // Create the Vault with the total supply of tokens and save it in storage
        //
        let vault <- create Vault(balance: self.totalSupply)
        self.account.save(<-vault, to: /storage/UsdcVault)

        // Create a public capability to the stored Vault that only exposes
        // the `deposit` method through the `Receiver` interface
        //
        adminAccount.link<&USDC.Vault{FungibleToken.Receiver}>(
            /public/UsdcReceiver,
            target: /storage/UsdcVault
        )

        // Create a public capability to the stored Vault that only exposes
        // the `balance` field through the `Balance` interface
        //
        adminAccount.link<&USDC.Vault{FungibleToken.Balance}>(
            /public/UsdcBalance,
            target: /storage/UsdcVault
        )

        // Note: the account deploying this contract can upgrade the contract, aka the admin role in the token design doc
        // Saving the owner here means the admin and the owner is under management of the same account
        //

        self.OwnerStoragePath = /storage/UsdcOwner;
        self.PauseExecutorStoragePath = /storage/UsdcPauseExec;
        self.BlockListExecutorStoragePath = /storage/UsdcBlockListExec;
        self.MasterMinterStoragePath = /storage/UsdcMasterMinter;

        self.OwnerPrivPath = /private/UsdcOwner;
        self.PauseExecutorPrivPath = /private/UsdcPauserExec;
        self.BlockListExecutorPrivPath = /private/UsdcBlockListExec;
        self.MasterMinterPrivPath = /private/UsdcMasterMinter;

        let owner <- create Owner()
        adminAccount.save(<-owner, to: /storage/UsdcOwner);
        adminAccount.link<&Owner>(self.OwnerPrivPath, target: self.OwnerStoragePath);
        

        // Create all the owner resources where capabilities can be shared.
        let ownerCap = adminAccount.getCapability<&Owner>(self.OwnerPrivPath);
        adminAccount.save(<-ownerCap.borrow()?.createNewPauseExecutor(), to: self.PauseExecutorStoragePath);
        adminAccount.save(<-ownerCap.borrow()?.createNewBlockListExecutor(), to: self.BlockListExecutorStoragePath);
        adminAccount.save(<-ownerCap.borrow()?.createNewMasterMinter(), to: self.MasterMinterStoragePath);
        
        adminAccount.link<&PauseExecutor>(self.PauseExecutorPrivPath, target: self.PauseExecutorStoragePath);
        adminAccount.link<&BlockListExecutor>(self.BlockListExecutorPrivPath, target: self.BlockListExecutorStoragePath);
        adminAccount.link<&MasterMinter>(self.MasterMinterPrivPath, target: self.MasterMinterStoragePath);

        // Emit an event that shows that the contract was initialized
        //
        emit TokensInitialized(initialSupply: self.totalSupply)

    }
} 
