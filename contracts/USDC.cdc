import FungibleToken from 0x{{.FungibleToken}} 
import USDCInterface from 0x{{.USDCInterface}}

pub contract USDC: USDCInterface, FungibleToken {

    // ===== Contract Paths =====
    pub let OwnerStoragePath: StoragePath;
    pub let PauseExecutorStoragePath: StoragePath;
    pub let BlocklistExecutorStoragePath: StoragePath;
    pub let MasterMinterStoragePath: StoragePath;

    pub let OwnerPrivPath: PrivatePath;
    pub let PauseExecutorPrivPath: PrivatePath;
    pub let BlocklistExecutorPrivPath: PrivatePath;
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
    pub event BlocklisterCreated();
    
    /// ===== USDC Vault events =====
    /// NewVault 
    ///
    /// The event that is emitted when new vault resource has been created 
    pub event NewVault(resourceId: UInt64);
    /// Destroy Vault 
    ///
    /// The event that is emitted when a vault resource has been destroyed 
    pub event DestroyVault(resourceId: UInt64);
    /// USDCWithdrawn
    ///
    /// The event that is emitted when tokens are withdrawn from a USDC Vault
    /// note we emit UUID as blocklisting requires this 
    pub event USDCWithdrawn(amount: UFix64, from: UInt64);
    /// USDCDeposited
    ///
    /// The event that is emitted when tokens are deposited into a USDC Vault
    /// note we emit UUID as blocklisting requires this 
    pub event USDCDeposited(amount: UFix64, to: UInt64);
    /// Approval 
    ///
    /// The event that is emitted when a USDC vault approves another to  
    /// withdraw some set allowance 
    pub event Approval(fromResourceId: UInt64, toResourceId: UInt64, amount: UFix64);

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
    
    pub resource Vault: USDCInterface.VaultUUID, USDCInterface.Allowance, FungibleToken.Provider, FungibleToken.Receiver, FungibleToken.Balance {

        // initialize the balance at resource creation time
        init(balance: UFix64) {
            self.balance = balance;
            self.allowed = {};
        }
        
        // ===== Fungible Token Interfaces =====

        /// The total balance of this vault
        pub var balance: UFix64

        // Fungible token Provider interface 
        pub fun withdraw(amount: UFix64): @FungibleToken.Vault {
            pre {
                !USDC.paused: "USDC contract paused" 
                USDC.blocklist[self.uuid] == nil: "Vault Blocklisted"
            }
            // todo check blocklist and pause state
            self.balance = self.balance - amount
            emit USDCWithdrawn(amount: amount, from: self.uuid);
            emit TokensWithdrawn(amount: amount, from: self.owner?.address);
            return <-create Vault(balance: amount);
        }

        // Fungible token Receiver interface 
        pub fun deposit(from: @FungibleToken.Vault) {
            pre {
                !USDC.paused: "USDC contract paused" 
                USDC.blocklist[self.uuid] == nil: "Vault Blocklisted"
            }
            // todo check blocklist and pause state 
            let vault <- from as! @USDC.Vault
            self.balance = self.balance + vault.balance
            emit USDCDeposited(amount: vault.balance, to: self.uuid);
            emit TokensDeposited(amount: vault.balance, to: self.owner?.address)
            vault.balance = 0.0
            destroy vault 
        }

        
        // ===== USDC interfacas =====

        /// USDC VaultUUID Interface: should be linked to the public domain 
        /// uuid is implicitly created on resource init
        /// lets owner share uuid but there is not guarantee they would
        pub fun UUID(): UInt64 {
            return self.uuid;
        }

        /// The allowances state of this vault
        ///
        /// Receiving vault uuid : Amount
        pub var allowed: {UInt64: UFix64};

        /// Public interface to check allowance
        ///
        /// Returns allowance if any
        pub fun allowance(resourceId: UInt64): UFix64? {
           return self.allowed[resourceId];
        }

        /// Public interface to withdraw allowance
        ///
        /// Anyone can call this but the allowance would be transfered to 
        /// the vault stored at the recv addr
        pub fun withdrawAllowance(recvAddr: Address, amount: UFix64) {
            let to = getAccount(recvAddr);
            // TODO: perhaps allow path as an arg
            let idRef = to.getCapability(/public/UsdcVaultUUID)
                .borrow<&{USDCInterface.VaultUUID}>()
                ?? panic("Could not borrow uuid reference to the recipient's Vault")

            let resourceId = idRef.UUID(); 
            
            assert(self.allowed.containsKey(resourceId), message: "no allowance provided for resource");
            let allowance = self.allowed[resourceId]!;
            assert(allowance >= amount, message: "requested amount more than allowed");
            self.allowed.insert(key: resourceId, allowance - amount);
            
            let v <- self.withdraw(amount:amount);

            let receiverRef = to.getCapability(/public/UsdcReceiver)
                .borrow<&{FungibleToken.Receiver}>()
                ?? panic("Could not borrow receiver reference to the recipient's Vault")
    
            receiverRef.deposit(from: <-v)
        }

        // ===== Private capabilities to set / modify allowances

        /// Sets allowance for this vault
        pub fun approval(resourceId: UInt64, amount: UFix64) {
            if (amount != 0.0){
                self.allowed.insert(key: resourceId, amount);
            } else {
                assert(self.allowed.containsKey(resourceId), message: "cannot set zero allowance")
                self.allowed.remove(key: resourceId)
            }
            emit Approval(fromResourceId: self.uuid, toResourceId: resourceId, amount: amount);
        }

        /// Increase current allowance by increment value 
        pub fun increaseAllowance(resourceId: UInt64, increment: UFix64){
            let allowance = self.allowed[resourceId] ?? 0.0;
            let newAllowance = allowance.saturatingAdd(increment);
            self.approval(resourceId: resourceId, amount: newAllowance);
        };

        /// Decrease current allowance by decrement value 
        pub fun decreaseAllowance(resourceId: UInt64, decrement: UFix64){
            let allowance = self.allowed[resourceId]!;
            let newAllowance = allowance.saturatingSubtract(decrement);
            self.approval(resourceId: resourceId, amount: newAllowance);
        };


        destroy() {
            USDC.totalSupply = USDC.totalSupply - self.balance
            emit DestroyVault(resourceId: self.uuid);
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

        pub fun createNewBlocklistExecutor(): @BlocklistExecutor{
            // todo set cap
            return <-create BlocklistExecutor()
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
        
        pub fun configureManagedMinter (cap: Capability<&AnyResource{USDCInterface.MasterMinter}>, newManagedMinter: UInt64?) {
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
    /// with Blocklister to managed permission for block
    pub resource BlocklistExecutor: USDCInterface.Blocklister{

        pub fun blocklist(resourceId: UInt64){
            let block = getCurrentBlock();
            USDC.blocklist.insert(key: resourceId, block.height);
            emit Blocklisted(resourceId: resourceId);
        };

        pub fun unblocklist(resourceId: UInt64){
            USDC.blocklist.remove(key: resourceId);
            emit Unblocklisted(resourceId: resourceId);
        };
    }

    pub resource interface BlocklistCapReceiver {
        // This is used to set the blocklist capability of a Blocklister
        pub fun setBlocklistCap(blocklistCap: Capability<&BlocklistExecutor>) 
    }

    /// Delegate blocklister for actually adding resources to blocklist
    //  Blocklisting is not paused in the event the contract is paused\
    // https://github.com/centrehq/centre-tokens/blob/master/doc/tokendesign.md#pausing
    pub resource Blocklister: BlocklistCapReceiver {
        // Optional value, initially nil until set by BlocklistExecutor
        access(self) var blocklistcap: Capability<&BlocklistExecutor>?;
        
        pub fun blocklist(resourceId: UInt64){
            pre {
                !USDC.blocklist.containsKey(resourceId): "Resource already on blocklist"
            }
            self.blocklistcap!.borrow()!.blocklist(resourceId: resourceId);
        };

        pub fun unblocklist(resourceId: UInt64){
            pre {
                USDC.blocklist.containsKey(resourceId): "Resource not on blocklist"
            }
            self.blocklistcap!.borrow()!.unblocklist(resourceId: resourceId);
        };
        
        pub fun setBlocklistCap(blocklistCap: Capability<&BlocklistExecutor>){
            pre {
                blocklistCap.borrow() != nil: "Invalid BlocklistCap capability"
            }
            self.blocklistcap = blocklistCap;
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
        // This is used by some account with the PauseExecutor resource
        // to share it with a Pauser
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
            pre {
                pauseCap.borrow() != nil: "Invalid PauseCap capability"
            }
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
        let r <-create Vault(balance: 0.0);
        emit NewVault(resourceId: r.uuid);
        return <-r;
    }

    pub fun createNewPauser(): @Pauser{
        emit PauserCreated();
        return <-create Pauser()
    }

    pub fun createMinterController(): @MinterController{
        // todo set cap
        return <-create MinterController()
    }

    pub fun createNewBlocklister(): @Blocklister{
        emit BlocklisterCreated();
        return <-create Blocklister()
    }

    init(adminAccount: AuthAccount){
        self.paused = false;
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

        // Create a public capability to the stored Vault that only exposes
        // the `uuid` field through the `VaultUUID` interface
        //
        adminAccount.link<&USDC.Vault{USDCInterface.VaultUUID}>(
            /public/UsdcVaultUUID,
            target: /storage/UsdcVault
        )

        // Create a public capability to the stored Vault that only exposes
        // the `withdrawAllowance` method through the `WithdrawAllowance` interface
        //
        adminAccount.link<&USDC.Vault{USDCInterface.Allowance}>(
            /public/UsdcVaultAllowance,
            target: /storage/UsdcVault
        )

        // Note: the account deploying this contract can upgrade the contract, aka the admin role in the token design doc
        // Saving the owner here means the admin and the owner is under management of the same account
        //

        self.OwnerStoragePath = /storage/UsdcOwner;
        self.PauseExecutorStoragePath = /storage/UsdcPauseExec;
        self.BlocklistExecutorStoragePath = /storage/UsdcBlocklistExec;
        self.MasterMinterStoragePath = /storage/UsdcMasterMinter;

        self.OwnerPrivPath = /private/UsdcOwner;
        self.PauseExecutorPrivPath = /private/UsdcPauserExec;
        self.BlocklistExecutorPrivPath = /private/UsdcBlocklistExec;
        self.MasterMinterPrivPath = /private/UsdcMasterMinter;

        let owner <- create Owner()
        adminAccount.save(<-owner, to: self.OwnerStoragePath);
        adminAccount.link<&Owner>(self.OwnerPrivPath, target: self.OwnerStoragePath);
        

        // Create all the owner resources where capabilities can be shared.
        let ownerCap = adminAccount.getCapability<&Owner>(self.OwnerPrivPath);
        adminAccount.save(<-ownerCap.borrow()!.createNewPauseExecutor(), to: self.PauseExecutorStoragePath);
        adminAccount.save(<-ownerCap.borrow()!.createNewBlocklistExecutor(), to: self.BlocklistExecutorStoragePath);
        adminAccount.save(<-ownerCap.borrow()!.createNewMasterMinter(), to: self.MasterMinterStoragePath);
        
        adminAccount.link<&PauseExecutor>(self.PauseExecutorPrivPath, target: self.PauseExecutorStoragePath);
        adminAccount.link<&BlocklistExecutor>(self.BlocklistExecutorPrivPath, target: self.BlocklistExecutorStoragePath);
        adminAccount.link<&MasterMinter>(self.MasterMinterPrivPath, target: self.MasterMinterStoragePath);

        // Emit an event that shows that the contract was initialized
        //
        emit TokensInitialized(initialSupply: self.totalSupply)

    }
} 
