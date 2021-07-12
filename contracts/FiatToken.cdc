import FungibleToken from 0x{{.FungibleToken}} 
import FiatTokenInterface from 0x{{.FiatTokenInterface}}

// Below helps debug when using language server
// import FungibleToken from "./FungibleToken.cdc"
// import FiatTokenInterface from "./FiatTokenInterface.cdc" 

pub contract FiatToken: FiatTokenInterface, FungibleToken {
    
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
    
    /// ===== FiatToken Vault events =====
    /// NewVault 
    ///
    /// The event that is emitted when new vault resource has been created 
    pub event NewVault(resourceId: UInt64);
    /// Destroy Vault 
    ///
    /// The event that is emitted when a vault resource has been destroyed 
    pub event DestroyVault(resourceId: UInt64);
    /// FiatTokenWithdrawn
    ///
    /// The event that is emitted when tokens are withdrawn from a FiatToken Vault
    /// note we emit UUID as blocklisting requires this 
    pub event FiatTokenWithdrawn(amount: UFix64, from: UInt64);
    /// FiatTokenDeposited
    ///
    /// The event that is emitted when tokens are deposited into a FiatToken Vault
    /// note we emit UUID as blocklisting requires this 
    pub event FiatTokenDeposited(amount: UFix64, to: UInt64);
    /// Approval 
    ///
    /// The event that is emitted when a FiatToken vault approves another to  
    /// withdraw some set allowance 
    pub event Approval(fromResourceId: UInt64, toResourceId: UInt64, amount: UFix64);

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
    /// Currently only support allowance
    pub event MinterConfigured(controller: UInt64, minter: UInt64, allowance: UFix64);
    /// MinterRemoved
    ///
    /// The event that is emitted when minter controller has removed the minter 
    pub event MinterRemoved(controller: UInt64, minter: UInt64);
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
    pub event ControllerRemoved(controller: UInt64);
    
    // ===== Fungible Token state and events =====

    /// Total supply of FiatToken in existence
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
 
    // ===== FiatToken Resources: =====
    
    pub resource Vault: FiatTokenInterface.VaultUUID, FiatTokenInterface.Allowance, FungibleToken.Provider, FungibleToken.Receiver, FungibleToken.Balance {

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
                !FiatToken.paused: "FiatToken contract paused" 
                FiatToken.blocklist[self.uuid] == nil: "Vault Blocklisted"
            }
            // todo check blocklist and pause state
            self.balance = self.balance - amount
            emit FiatTokenWithdrawn(amount: amount, from: self.uuid);
            emit TokensWithdrawn(amount: amount, from: self.owner?.address);
            return <-create Vault(balance: amount);
        }

        // Fungible token Receiver interface 
        pub fun deposit(from: @FungibleToken.Vault) {
            pre {
                !FiatToken.paused: "FiatToken contract paused" 
                FiatToken.blocklist[self.uuid] == nil: "Vault Blocklisted"
            }
            // todo check blocklist and pause state 
            let vault <- from as! @FiatToken.Vault
            self.balance = self.balance + vault.balance
            emit FiatTokenDeposited(amount: vault.balance, to: self.uuid);
            emit TokensDeposited(amount: vault.balance, to: self.owner?.address)
            vault.balance = 0.0
            destroy vault 
        }

        
        // ===== FiatToken interfacas =====

        /// FiatToken VaultUUID Interface: should be linked to the public domain 
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
            let idRef = to.getCapability(FiatToken.VaultUUIDPubPath)
                .borrow<&{FiatTokenInterface.VaultUUID}>()
                ?? panic("Could not borrow uuid reference to the recipient's Vault")

            let resourceId = idRef.UUID(); 
            
            assert(self.allowed.containsKey(resourceId), message: "no allowance provided for resource");
            let allowance = self.allowed[resourceId]!;
            assert(allowance >= amount, message: "insufficient allowance");
            self.allowed.insert(key: resourceId, allowance - amount);
            
            let v <- self.withdraw(amount:amount);

            let receiverRef = to.getCapability(FiatToken.VaultReceiverPubPath)
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
            FiatToken.totalSupply = FiatToken.totalSupply - self.balance
            emit DestroyVault(resourceId: self.uuid);
        }
    }
    
    

    /// The owner is defined in https://github.com/centrehq/centre-tokens/blob/master/doc/tokendesign.md
    ///
    /// Owner can assign all roles
    pub resource Owner {

        pub fun createNewPauseExecutor(): @PauseExecutor{
            return <-create PauseExecutor()
        }

        pub fun createNewBlocklistExecutor(): @BlocklistExecutor{
            return <-create BlocklistExecutor()
        }

        pub fun createNewMasterMinter(): @MasterMinter{
            return <-create MasterMinter()
        }
    }

    /// The master minter is defined in https://github.com/centrehq/centre-tokens/blob/master/doc/tokendesign.md
    ///
    /// The master minter creates minter controller resources to delegate control for minters
    pub resource MasterMinter: FiatTokenInterface.MasterMinter {

        /// Function to configure MinterController
        pub fun configureMinterController(minter: UInt64, minterController: UInt64) {
            /// we overwrite the key here since minterController can only control 1 minter
            FiatToken.managedMinters.insert(key: minterController, minter);
            emit ControllerConfigured(controller: minterController, minter: minter)
        }
        
        /// Function to remove MinterController
        pub fun removeMinterController(minterController: UInt64){
            assert(FiatToken.managedMinters.containsKey(minterController), message: "cannot remove unknown minter controller");
            FiatToken.managedMinters.remove(key: minterController);
            emit ControllerRemoved(controller: minterController)
        }
    }
    
    pub resource interface ResourceId{
        pub fun UUID(): UInt64; 
    }

    /// This is a resource to manage minters, delegated from MasterMinter
    pub resource MinterController: FiatTokenInterface.MinterController, ResourceId {

        /// The resourceId this MinterController manages
        pub fun managedMinter(): UInt64? {
            return FiatToken.managedMinters[self.uuid];
        }

        pub fun UUID(): UInt64 {
            return self.uuid;
        }

        /// configureMinter 
        ///
        /// Function that updates existing minter restrictions
        pub fun configureMinterAllowance(allowance: UFix64) {
            pre {
                FiatToken.managedMinters.containsKey(self.uuid): "controller does not manage any minters"
            }
            let managedMinter = self.managedMinter()!;
            FiatToken.minterAllowances[managedMinter] = allowance;
            emit MinterConfigured(controller: self.uuid, minter: managedMinter, allowance: allowance);
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
            pre {
                FiatToken.managedMinters.containsKey(self.uuid): "controller does not manage any minters"
            }
            let managedMinter = self.managedMinter()!;
            assert(FiatToken.minterAllowances.containsKey(minter), message: "cannot remove unknown minter");
            FiatToken.minterAllowances.remove(key: minter);
            emit MinterRemoved(controller: self.uuid, minter: minter)
        }
    }

    /// The actual minter resource, the resourceId must be added to the minter restrictions lists
    /// for minter to successfully mint / burn within restrictions
    pub resource Minter: FiatTokenInterface.Minter, ResourceId {

        pub fun UUID(): UInt64 {
            return self.uuid
        }

        pub fun mint(amount: UFix64): @FungibleToken.Vault{
            pre{
                FiatToken.minterAllowances.containsKey(self.uuid): "minter does not have allowance set"
            }
            let mintAllowance = FiatToken.minterAllowances[self.uuid]!;
            assert(mintAllowance >= amount, message: "insufficient mint allowance");
            FiatToken.minterAllowances.insert(key: self.uuid, mintAllowance - amount);
            let newTotalSupply = FiatToken.totalSupply + amount;
            FiatToken.totalSupply = newTotalSupply;
            return <-create Vault(balance: amount);
        }
        
        /// Burn tokens called by minter reduces the totalSupply of the tokens
        /// Burning tokens does not increase minting allowance
        // https://github.com/centrehq/centre-tokens/blob/master/doc/tokendesign.md#burning
        pub fun burn(vault: @FungibleToken.Vault) {
            let amount = vault.balance;
            assert(FiatToken.totalSupply >= amount, message: "burning more than total supply");
            let newTotalSupply = FiatToken.totalSupply - amount;
            FiatToken.totalSupply = newTotalSupply;
            destroy vault;
        }
    }

    /// The blocklist execution resource, account with this resource must share / unlink its capability
    /// with Blocklister to managed permission for block
    pub resource BlocklistExecutor: FiatTokenInterface.Blocklister{

        pub fun blocklist(resourceId: UInt64){
            let block = getCurrentBlock();
            FiatToken.blocklist.insert(key: resourceId, block.height);
            emit Blocklisted(resourceId: resourceId);
        };

        pub fun unblocklist(resourceId: UInt64){
            FiatToken.blocklist.remove(key: resourceId);
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
                !FiatToken.blocklist.containsKey(resourceId): "Resource already on blocklist"
            }
            self.blocklistcap!.borrow()!.blocklist(resourceId: resourceId);
        };

        pub fun unblocklist(resourceId: UInt64){
            pre {
                FiatToken.blocklist.containsKey(resourceId): "Resource not on blocklist"
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
    pub resource PauseExecutor: FiatTokenInterface.Pauser {
        // Note: this only sets the state of the pause of the contract
        pub fun pause() {
            FiatToken.paused = true;
            emit Paused();
         }
        pub fun unpause() { 
            FiatToken.paused = false;
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

    // ============ FiatToken METHODS: ==============

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

    pub fun createNewMinterController(): @MinterController{
        return <-create MinterController()
    }

    pub fun createNewMinter(): @Minter{
        return <-create Minter()
    }

    pub fun createNewBlocklister(): @Blocklister{
        emit BlocklisterCreated();
        return <-create Blocklister()
    }

    init(
        adminAccount: AuthAccount, 
        VaultStoragePath: StoragePath,
        VaultBalancePubPath: PublicPath,
        VaultUUIDPubPath: PublicPath,
        VaultAllowancePubPath: PublicPath,
        VaultReceiverPubPath: PublicPath,
        BlocklistExecutorStoragePath: StoragePath,
        BlocklistExecutorPrivPath: PrivatePath,
        BlocklisterStoragePath: StoragePath,
        BlocklisterCapReceiverPubPath: PublicPath,
        PauseExecutorStoragePath: StoragePath,
        PauseExecutorPrivPath: PrivatePath,
        PauserStoragePath: StoragePath,
        PauserCapReceiverPubPath: PublicPath,
        OwnerStoragePath: StoragePath,
        OwnerPrivPath: PrivatePath,
        MasterMinterStoragePath: StoragePath,
        MasterMinterPrivPath: PrivatePath,
        MinterControllerStoragePath: StoragePath,
        MinterControllerUUIDPubPath: PublicPath,
        MinterStoragePath: StoragePath,
        MinterUUIDPubPath: PublicPath,
        tokenName: String,
        initTotalSupply: UFix64,
        initPaused: Bool
    ) {
        self.name = tokenName;
        self.paused = initPaused;
        self.totalSupply = initTotalSupply;
        self.blocklist = {};
        self.minterAllowances = {};
        self.minterDeadlines = {};
        self.minterReceivers = {};
        self.managedMinters = {};

        // Note: the account deploying this contract can upgrade the contract, aka the admin role in the token design doc
        // Saving the owner here means the admin and the owner is under management of the same account

        self.VaultStoragePath = VaultStoragePath;
        self.VaultBalancePubPath = VaultBalancePubPath;
        self.VaultUUIDPubPath = VaultUUIDPubPath;
        self.VaultAllowancePubPath = VaultAllowancePubPath;
        self.VaultReceiverPubPath = VaultReceiverPubPath;

        self.BlocklistExecutorStoragePath =  BlocklistExecutorStoragePath;
        self.BlocklistExecutorPrivPath = BlocklistExecutorPrivPath;

        self.BlocklisterStoragePath =  BlocklisterStoragePath;
        self.BlocklisterCapReceiverPubPath = BlocklisterCapReceiverPubPath;

        self.PauseExecutorStoragePath = PauseExecutorStoragePath; 
        self.PauseExecutorPrivPath = PauseExecutorPrivPath;

        self.PauserStoragePath = PauseExecutorStoragePath; 
        self.PauserCapReceiverPubPath = PauserCapReceiverPubPath;

        self.OwnerStoragePath = OwnerStoragePath;
        self.OwnerPrivPath = OwnerPrivPath;

        self.MasterMinterStoragePath = MasterMinterStoragePath;
        self.MasterMinterPrivPath = MasterMinterPrivPath;

        self.MinterControllerStoragePath = MinterControllerStoragePath;
        self.MinterControllerUUIDPubPath = MinterControllerUUIDPubPath;

        self.MinterStoragePath = MinterStoragePath;
        self.MinterUUIDPubPath = MinterUUIDPubPath;

        // Create the Vault with the total supply of tokens and save it in storage
        //
        let vault <- create Vault(balance: self.totalSupply)
        self.account.save(<-vault, to: self.VaultStoragePath)

        // Create a public capability to the stored Vault that only exposes
        // the `deposit` method through the `Receiver` interface
        //
        adminAccount.link<&FiatToken.Vault{FungibleToken.Receiver}>(
            self.VaultReceiverPubPath,
            target: self.VaultStoragePath 
        )

        // Create a public capability to the stored Vault that only exposes
        // the `balance` field through the `Balance` interface
        //
        adminAccount.link<&FiatToken.Vault{FungibleToken.Balance}>(
            self.VaultBalancePubPath,
            target: self.VaultStoragePath 
        )

        // Create a public capability to the stored Vault that only exposes
        // the `uuid` field through the `VaultUUID` interface
        //
        adminAccount.link<&FiatToken.Vault{FiatTokenInterface.VaultUUID}>(
            self.VaultUUIDPubPath,
            target: self.VaultStoragePath 
        )

        // Create a public capability to the stored Vault that only exposes
        // the `withdrawAllowance` method through the `WithdrawAllowance` interface
        //
        adminAccount.link<&FiatToken.Vault{FiatTokenInterface.Allowance}>(
            self.VaultAllowancePubPath,
            target: self.VaultStoragePath 
        )


        let owner <- create Owner()
        adminAccount.save(<-owner, to: self.OwnerStoragePath);
        // TODO: do we need to link this? 
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
