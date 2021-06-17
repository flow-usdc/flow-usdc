import FungibleToken from "./FungibleToken.cdc"
import TokenPauser from "./interfaces/TokenPauser.cdc"
import TokenBlockLister from "./interfaces/TokenBlockedLister.cdc"

pub contract USDC: FungibleToken, TokenPauser, TokenBlockLister {

    /// Total supply of usdc in existence
    pub var totalSupply: UFix64;
    
    // Pause Interfaces 
    pub var paused: Bool;
    pub event Paused();
    pub event Unpaused();

    // Blocklist Interfaces
    pub event Blocked(account: Address);
    pub event Unblocked(account: Address);

    // Minters Allowance 
    // Not sure if we revoke minting Capability after certain allowance?
    pub var mintersAllowance: { Address: UFix64 };

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
    /// The event that is emitted when tokens are deposited to a Vault
    pub event TokensDeposited(amount: UFix64, to: Address?)

    /// TokensMinted
    ///
    /// The event that is emitted when new tokens are minted
    pub event TokensMinted(amount: UFix64)

    /// TokensBurned
    ///
    /// The event that is emitted when tokens are destroyed
    pub event TokensBurned(amount: UFix64)

    /// MinterCreated
    ///
    /// The event that is emitted when a new minter resource is created
    pub event MinterCreated(allowedAmount: UFix64)

    /// PauserCreated 
    ///
    /// The event that is emitted when a new minter resource is created
    pub event PauserCreated(allowedAmount: UFix64)

    /// BurnerCreated
    ///
    /// The event that is emitted when a new burner resource is created
    pub event BurnerCreated()

    /// BlocklisterCreated
    ///
    /// The event that is emitted when a new minter resource is created
    pub event BlocklisterCreated()

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
            self.balance = self.balance - amount
            emit TokensWithdrawn(amount: amount, from: self.owner?.address)
            return <-create Vault(balance: amount)
        }

        pub fun deposit(from: @FungibleToken.Vault) {
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

    pub resource MasterMinter {

        // TO DISCUSS:
        // Perhaps the MasterMinter creates all the below
        // then link / unlink capability for each resource 

        pub fun createNewBurner(): @Burner {
            emit BurnerCreated()
            return <-create Burner()
        }

        pub fun createNewBlockLister(): @BlockedLister{
            emit BurnerCreated()
            return <-create BlockedLister()
        }

        pub fun createNewPauser(): @Pauser{
            emit PauserCreated()
            return <-create Pauser()
        }

        // TODO: does masterminter also creates minter? 
        pub fun createNewMinterController(): @MinterController{
            emit MinterCreated()
            return <-create MinterController()
        }
    }

    pub resource MinterController {
        // TODO make sure it can only control 1 minter
        // Similar to controller in solidity impl

        /// Function that creates and returns a new minter resource
        pub fun createNewMinter(allowedAmount: UFix64): @Minter {
            // update minterAllowance 
            return <- create Minter();
        }

        /// configureMinter 
        ///
        /// Function that updates existing minter allowance 
        /// How to revoke access automatically when all minted?
        pub fun configureMinterAllowance(newAllowedAmount: UFix64) {
        }

    }

    pub resource BlockedLister: TokenBlockLister.UpdateBlockList {
        pub fun block(account: Address){// TODO};
        pub fun unblock(account: Address){// TODO};
    }

    pub resource PauseExecutor: TokenPauser.Execute {
        // Note: this only sets the state of the pause of the contract
        // 
        // In order to pause transactions, each Vault will have to have their capabilities removed?
        pub fun pause() { 
            self.paused = true;
            emit Paused();
         }
        pub fun unpause() { 
            self.paused = false;
            emit Unpaused();
         }
    }

    pub resource Pauser {
        // This will be a Capability from the PauseExecutor created by the MasterMinter and linked privately.
        // MasterMinter will call setPauseCapability to provide it.
        access(self) var pauseCapability:  Capbility<&PauseExecutor>;
        
        // Called by the Account that owns PauseExecutor
        // (since they are the only account that can create such Capability as input arg)
        // This means the PauseExector account "grants" the right to call fn in pauseExecutor
        // 
        // The Account that owns PauseExecutor will be set in init() of the contract
        // and will probably be the MasterMinter/Admin
        pub setPauseCapability(pauseCap: Capability<&PauseExecutor>) {
            self.pauseCapbility = pauseCap;
        }

        // Pauser can borrow the pauseCapability, if it exists, and pause and unpause the contract
        pub pause(){
            let cap = self.pauseCapbility.borrow()!
            cap.pause();
        } 
        
        pub unpause(){
            let cap = self.pauseCapbility.borrow()!
            cap.unpause();
        } 

    }

    pub resource Minter {
        // check allowance
        pub fun mintTokens(amount: UFix64): @FungibleToken.Vault {
            // do we create these for others to store
            // or keep and and only link capability and check address?
            return <-create Vault(balance: amount);
        }
    }

    pub resource Burner {
        /// burnTokens
        ///
        /// Function that destroys a Vault instance, effectively burning the tokens.
        ///
        /// Note: the burned tokens are automatically subtracted from the
        /// total supply in the Vault destructor.
        ///
        // BELOW has not been changed  
        pub fun burnTokens(from: @FungibleToken.Vault) {
            let vault <- from as! @USDC.Vault
            let amount = vault.balance
            destroy vault
            emit TokensBurned(amount: amount)
        }
    }
    
    // ============ USDC METHODS: ==============
    // 
    // 
    pub fun createNewMasterMinter(): @MasterMinter{
        return <-create MasterMinter()
    }

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

    init() {
        self.totalSupply = 1000.0
        self.paused = true;
        self.blockedlist = {};
        self.mintersAllowance = {};

        // Create the Vault with the total supply of tokens and save it in storage
        //
        // let vault <- create Vault(balance: self.totalSupply)
        // self.account.save(<-vault, to: /storage/exampleTokenVault)

        // Create a public capability to the stored Vault that only exposes
        // the `deposit` method through the `Receiver` interface
        //
        // self.account.link<&{FungibleToken.Receiver}>(
        //     /public/exampleTokenReceiver,
        //     target: /storage/exampleTokenVault
        // )

        // Create a public capability to the stored Vault that only exposes
        // the `balance` field through the `Balance` interface
        //
        // self.account.link<&ExampleToken.Vault{FungibleToken.Balance}>(
        //     /public/exampleTokenBalance,
        //     target: /storage/exampleTokenVault
        // )

        // let admin <- create Administrator()
        // self.account.save(<-admin, to: /storage/exampleTokenAdmin)

        // Emit an event that shows that the contract was initialized
        //
        emit TokensInitialized(initialSupply: self.totalSupply)
    }
}

