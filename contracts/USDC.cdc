import FungibleToken from "./FungibleToken.cdc"

pub contract USDC: FungibleToken {

    /// Total supply of usdc in existence
    pub var totalSupply: UFix64;

    // Pause state and events 
    pub var paused: Bool;
    pub event Paused();
    pub event Unpaused();
    /// PauserCreated 
    ///
    /// The event that is emitted when a new pauser resource is created
    pub event PauserCreated(allowedAmount: UFix64)

    // Blocklist state and events 
    pub var blocklist: {UInt64: Bool}
    pub event Blocklisted(resourceId: UInt64);
    pub event Unblocklisted(resourceId: UInt64);
    /// BlocklisterCreated
    ///
    /// The event that is emitted when a new blocklister resource is created
    pub event BlocklisterCreated()

    /// Dict of all minters and their allowances
    pub var minterAllowances: { UInt64: UFix64};
    /// Dict of all minters and their deadlines
    pub var minterDeadlines: { UInt64: UInt64};
    /// Dict of all minters and their restricted vault reciever
    pub var minterRecievers: { UInt64: UInt64};

    /// MinterCreated
    ///
    /// The event that is emitted when a new minter resource is created
    pub event MinterCreated(allowedAmount: UFix64);
    pub event MinterControllerCreated();
    /// Mint
    ///
    /// The event that is emitted when new tokens are minted
    pub event Mint(minter: UInt64, Amount: UFix64);
    /// Burn
    ///
    /// The event that is emitted when tokens are burnt by minter
    pub event Burn(minter: UInt64, Amount: UFix64);
    pub event MinterConfigured(minter: UInt64);
    pub event MinterRemoved(minter: UInt64);
    pub event MinterAllowanceIncreased(minter: UInt64, newAllowance: UFix64);
    pub event MinterAllowanceDecreased(minter: UInt64, newAllowance: UFix64);
    pub event ControllerConfigured(controller: UInt64, minter: UInt64);
    pub event ControllerRemoved(contorller: UInt64);
    
   /// TokensInitialized
    ///
    /// The event that is emitted when the contract is created
    ///
    pub event TokensInitialized(initialSupply: UFix64)

    /// TokensWithdrawn
    ///
    /// The event that is emitted when tokens are withdrawn from a Vault
    ///
    pub event TokensWithdrawn(amount: UFix64, from: Address?)

    /// TokensDeposited
    ///
    /// The event that is emitted when tokens are deposited into a Vault
    ///
    pub event TokensDeposited(amount: UFix64, to: Address?)
 
    // ============ USDC Resources: ==============
    // 
    // 
    
    pub resource Vault: FungibleToken.Provider, FungibleToken.Receiver, FungibleToken.Balance {

        /// The total balance of this vault
        pub var balance: UFix64

        // initialize the balance at resource creation time
        init(balance: UFix64) {
            self.balance = balance
        }

        pub fun withdraw(amount: UFix64): @FungibleToken.Vault {
            // todo check blocklist and pause state
            // if (Blocklist[self.id]){
            //     self.balance = self.balance - amount
            //         emit TokensWithdrawn(amount: amount, from: self.owner?.address)
            //         return <-create Vault(balance: amount)
            // } else {
            //     return Error
            // }
             return <-create Vault(balance: 0.0);
        }

        pub fun deposit(from: @FungibleToken.Vault) {
            // todo check blocklist and pause state 
            // let vault <- from as! @USDC.Vault
            // self.balance = self.balance + vault.balance
            // emit TokensDeposited(amount: vault.balance, to: self.owner?.address)
            // vault.balance = 0.0
            destroy from 
        }

        destroy() {
            USDC.totalSupply = USDC.totalSupply - self.balance
        }
    }
    
    

    pub resource Owner {

        pub fun createNewPauserExecutor(): @PauseExecutor{
            // todo set cap
            return <-create PauseExecutor()
        }

        pub fun createNewBlockListerExecutor(): @BlockListExecutor{
            // todo set cap
            return <-create BlockListExecutor()
        }

        pub fun createNewMasterMinter(): @MasterMinter{
            // todo set cap
            return <-create MasterMinter()
        }


    }

    pub resource MasterMinter {
        /// createNewMinterController
        ///  
        /// Allows MinterController to create, configure and remove Minter
        /// To be used when the Minter is created
        access(self) fun createNewMinterController(minter: UInt64): @MinterController{
            emit MinterControllerCreated()
            // todo set Minter for this controller cap
            return <-create MinterController(managedMinter: minter)
        }
     
        /// Function that creates and returns a new minter resource
        pub fun createNewMinter(allowance: UFix64): @Minter {
            // can only create 1
            // update minterAllowance 
            return <- create Minter();
        }
        
        /// removeMinterController
        /// 
        /// Function to remove MinterController
        /// This should remove the capability from the MasterMinter
        pub fun removeMinterController(minter: UInt64){
            // todo
        }
    }

    /// This is a resource to manage minters, delegated from MasterMinter
    pub resource MinterController {

        /// The resourceId this MinterController manages
        pub var managedMinter: UInt64;

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
        
        init(managedMinter: UInt64) {
            self.managedMinter = managedMinter;
         }
    }

    pub resource Minter {
        // todo: check allowance
        pub fun mint(amount: UFix64): @FungibleToken.Vault {
            return <-create Vault(balance: amount);
        }
        pub fun burn(vault: @Vault) {
            //todo
            destroy vault;
        }
    }

    pub resource BlockListExecutor {
        pub fun blocklist(resourceId: UInt64){
            // todo
        };
        pub fun unblocklist(resourceId: UInt64){
            // todo
        };
    }

    pub resource BlockedLister {
        access(self) var blocklistcap: Capability<&BlockListExecutor>;
        pub fun blocklist(resourceId: UInt64){
            // todo
        };
        pub fun unblocklist(resourceId: UInt64){
            // todo
        };
        
        pub fun setCapability(blocklistcap: Capability<&BlockListExecutor>){
            self.blocklistcap = blocklistcap;
        }
        
        init(blocklistcap: Capability<&BlockListExecutor>) {
           self.blocklistcap = blocklistcap;
        }
    }

    pub resource PauseExecutor {
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

    pub resource Pauser {
        // This will be a Capability from the PauseExecutor created by the MasterMinter and linked privately.
        // MasterMinter will call setPauseCapability to provide it.
        access(self) var pauseCap:  Capability<&PauseExecutor>;
        
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
            let cap = self.pauseCap.borrow()!
            cap.pause();
        } 
        
        pub fun unpause(){
            let cap = self.pauseCap.borrow()!
            cap.unpause();
        }

        init(pauseCap: Capability<&PauseExecutor>) {
            self.pauseCap = pauseCap;
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

    init(){
        self.paused = true;
        self.blocklist = {};
        self.totalSupply = 10000.0;
        self.minterAllowances = {};
        self.minterDeadlines = {};
        self.minterRecievers = {};

        // Create the Vault with the total supply of tokens and save it in storage
        //
        let vault <- create Vault(balance: self.totalSupply)
        self.account.save(<-vault, to: /storage/UsdcInitVault)

        // Create a public capability to the stored Vault that only exposes
        // the `deposit` method through the `Receiver` interface
        //
        self.account.link<&USDC.Vault{FungibleToken.Receiver}>(
            /public/UsdcInitVaultReceiver,
            target: /storage/UsdcInitVault
        )

        // Create a public capability to the stored Vault that only exposes
        // the `balance` field through the `Balance` interface
        //
        self.account.link<&USDC.Vault{FungibleToken.Balance}>(
            /public/UsdcInitVaultBalance,
            target: /storage/UsdcInitVault
        )

        let owner <- create Owner()
        self.account.save(<-owner, to: /storage/UsdcOwner);


        // Emit an event that shows that the contract was initialized
        //
        emit TokensInitialized(initialSupply: self.totalSupply)       

    }
} 
