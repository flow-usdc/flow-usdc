import Crypto
import FungibleToken from 0x{{.FungibleToken}} 
import FiatTokenInterface from 0x{{.FiatTokenInterface}}
import OnChainMultiSig from 0x{{.OnChainMultiSig}}

pub contract FiatToken: FiatTokenInterface, FungibleToken {

    // ===== FiatToken Events =====

    /// ===== Pause events =====
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
    pub event PauserCreated(resourceId: UInt64)

    // ===== Blocklist events =====
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
    pub event BlocklisterCreated(resourceId: UInt64);
    
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
    /// Note: we emit UUID as blocklisting requires this 
    pub event FiatTokenWithdrawn(amount: UFix64, from: UInt64);
    /// FiatTokenDeposited
    ///
    /// The event that is emitted when tokens are deposited into a FiatToken Vault
    /// Note: we emit UUID as blocklisting requires this 
    pub event FiatTokenDeposited(amount: UFix64, to: UInt64);
    /// Approval 
    ///
    /// The event that is emitted when a FiatToken vault approves another to  
    /// withdraw some set allowance 
    pub event Approval(from: UInt64, to: UInt64, amount: UFix64);
    /// ===== Minting events =====
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
    /// Currently only support allowance
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
    
    /// ===== Fungible Token vents =====
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
 

    // ===== FiatToken Paths =====

    pub let VaultStoragePath: StoragePath;
    pub let VaultBalancePubPath: PublicPath;
    pub let VaultUUIDPubPath: PublicPath;
    pub let VaultAllowancePubPath: PublicPath;
    pub let VaultReceiverPubPath: PublicPath;
    pub let VaultPubSigner: PublicPath;

    pub let BlocklistExecutorStoragePath: StoragePath;
    pub let BlocklistExecutorPrivPath: PrivatePath;
    
    pub let BlocklisterStoragePath: StoragePath;
    pub let BlocklisterCapReceiverPubPath: PublicPath;
    pub let BlocklisterPubSigner: PublicPath;

    pub let PauseExecutorStoragePath: StoragePath;
    pub let PauseExecutorPrivPath: PrivatePath;

    pub let PauserStoragePath: StoragePath;
    pub let PauserCapReceiverPubPath: PublicPath;
    pub let PauserPubSigner: PublicPath;

    pub let OwnerStoragePath: StoragePath;
    pub let OwnerPrivPath: PrivatePath;

    pub let MasterMinterStoragePath: StoragePath;
    pub let MasterMinterPrivPath: PrivatePath;
    pub let MasterMinterPubSigner: PublicPath;
    pub let MasterMinterUUIDPubPath: PublicPath;

    pub let MinterControllerStoragePath: StoragePath;
    pub let MinterControllerUUIDPubPath: PublicPath;
    pub let MinterControllerPubSigner: PublicPath;

    pub let MinterStoragePath: StoragePath;
    pub let MinterUUIDPubPath: PublicPath;
    pub let MinterPubSigner: PublicPath;
    

    // ===== FiatToken States / Variables =====

    pub let name: String;
    pub let version: String;
    /// paused 
    ///
    /// Contract is paused if `paused` is `true`
    /// All transactions must check this value
    /// No transaction, apart from unpaused, can occur when paused
    pub var paused: Bool;
    /// blocklist
    ///
    /// Dict of all blocklisted
    /// This is managed by the blocklister
    /// Resources such as Vaults and Minters can be blocked
    /// {resourceId: Block Height}
    access(contract) let blocklist: {UInt64: UInt64};
    /// managedMinters
    ///
    /// Dict of minter controller to their minter
    /// Only one minter per minter controller but each minter may be controller by multiple controllers
    /// The masterminter (owned by the owner of this contract) sets this
    /// https://github.com/centrehq/centre-tokens/blob/master/doc/masterminter.md#roles
    access(contract) let managedMinters: {UInt64: UInt64}
    /// minterAllowances
    ///
    /// Dict of all minters and their allowances
    /// Minting restricted to mint up to their allowance
    /// The minter controller sets this
    access(contract) let minterAllowances: { UInt64: UFix64};

    /// Total supply of FiatToken in existence
    /// Updated when mint, burn and vaults destroyed
    pub var totalSupply: UFix64;


    // ===== FiatToken Interfaces  =====

    /// ResourceId
    ///
    /// This allows resources' UUID to be shared
    /// uuid is implicitly created on resource init
    /// There is no guarantee owners of resources would
    pub resource interface ResourceId{
        pub fun UUID(): UInt64; 
    }
    /// BlocklistCapReceiver
    ///
    /// This must be linked Publicly so that the BlockListExecutor owner can have access to set this
    /// Without the Capability, Blocklisters cannot do any blocklist / unblocklist actions 
    pub resource interface BlocklistCapReceiver {
        // This is used to set the blocklist capability of a Blocklister
        pub fun setBlocklistCap(blocklistCap: Capability<&BlocklistExecutor>) 
    }
    /// PauseCapReceiver
    ///
    /// This must be linked Publicly so that the PauseExecutor owner can have access to set this
    /// Without the Capability, Pauser cannot do any pause/ unpause actions 
    pub resource interface PauseCapReceiver {
        // This is used by some account with the PauseExecutor resource
        // to share it with a Pauser
        pub fun setPauseCap(pauseCap: Capability<&PauseExecutor>) 
    }


    // ===== FiatToken Resources =====
    
    /// Vault
    ///
    /// The resource to hold FiatTokens
    /// It is compatible with FungibleToken Interfaces with addition functions 
    /// 1. Allowance: https://github.com/centrehq/centre-tokens/blob/master/contracts/v1/FiatTokenV1.sol#L172
    /// 2. OnChainMultiSig: https://github.com/flow-hydraulics/onchain-multisig
    pub resource Vault: 
        ResourceId, 
        FiatTokenInterface.Allowance, 
        FungibleToken.Provider, 
        FungibleToken.Receiver, 
        FungibleToken.Balance,
        OnChainMultiSig.KeyManager, 
        OnChainMultiSig.PublicSigner {

        // OnChainMultiSig Manager for storing publickeys, pending payloads, signatures, etc
        access(self) let multiSigManager: @OnChainMultiSig.Manager;

        /// The total balance of this vault
        pub var balance: UFix64

        /// The allowances state of this vault
        ///
        /// Receiving vault uuid : Amount
        access(self) let allowed: {UInt64: UFix64};

        // ===== Fungible Token Interfaces =====

        // Fungible token Provider interface 
        pub fun withdraw(amount: UFix64): @FungibleToken.Vault {
            pre {
                !FiatToken.paused: "FiatToken contract paused" 
                FiatToken.blocklist[self.uuid] == nil: "Vault Blocklisted"
            }
            self.balance = self.balance - amount
            emit FiatTokenWithdrawn(amount: amount, from: self.uuid);
            emit TokensWithdrawn(amount: amount, from: self.owner?.address);
            return <-create Vault(balance: amount);
        }

        // Fungible token Receiver interface 
        pub fun deposit(from: @FungibleToken.Vault) {
            pre {
                !FiatToken.paused: "FiatToken contract paused" 
                FiatToken.blocklist[from.uuid] == nil: "Receiving Vault Blocklisted"
                FiatToken.blocklist[self.uuid] == nil: "Vault Blocklisted"
            }
            let vault <- from as! @FiatToken.Vault
            self.balance = self.balance + vault.balance
            emit FiatTokenDeposited(amount: vault.balance, to: self.uuid);
            emit TokensDeposited(amount: vault.balance, to: self.owner?.address)
            vault.balance = 0.0
            destroy vault 
        }

        // ===== FiatToken interfacas =====

        /// Public interface to check UUID
        pub fun UUID(): UInt64 {
            return self.uuid;
        }

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
                .borrow<&{FiatToken.ResourceId}>()
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
        /// Owner of the vault can set allowance for this vault
        pub fun approval(resourceId: UInt64, amount: UFix64) {
            if (amount != 0.0){
                self.allowed.insert(key: resourceId, amount);
            } else {
                assert(self.allowed.containsKey(resourceId), message: "cannot set zero allowance")
                self.allowed.remove(key: resourceId)
            }
            emit Approval(from: self.uuid, to: resourceId, amount: amount);
        }

        /// Increase current allowance by increment value 
        pub fun increaseAllowance(resourceId: UInt64, increment: UFix64){
            let allowance = self.allowed[resourceId] ?? 0.0;
            let newAllowance = allowance.saturatingAdd(increment);
            self.approval(resourceId: resourceId, amount: newAllowance);
        };

        /// Decrease current allowance by decrement value 
        pub fun decreaseAllowance(resourceId: UInt64, decrement: UFix64){
            pre {
                self.allowed[resourceId] != nil: "Cannot decrease nil allowance"
            }
            let newAllowance = self.allowed[resourceId]!.saturatingSubtract(decrement);
            self.approval(resourceId: resourceId, amount: newAllowance);
        };

        // ===== OnChainMultiSig.PublicSigner interfaces
        pub fun addNewPayload(payload: @OnChainMultiSig.PayloadDetails, publicKey: String, sig: [UInt8]) {
            self.multiSigManager.addNewPayload(resourceId: self.uuid, payload: <-payload, publicKey: publicKey, sig: sig);
        }

        pub fun addPayloadSignature (txIndex: UInt64, publicKey: String, sig: [UInt8]) {
            self.multiSigManager.addPayloadSignature(resourceId: self.uuid, txIndex: txIndex, publicKey: publicKey, sig: sig);
       }
        pub fun executeTx(txIndex: UInt64): @AnyResource? {
            let p <- self.multiSigManager.readyForExecution(txIndex: txIndex) ?? panic ("no transactable payload at given txIndex")
            switch p.method {
                case "configureKey":
                    let pubKey = p.getArg(i: 0)! as? String ?? panic ("cannot downcast public key");
                    let weight = p.getArg(i: 1)! as? UFix64 ?? panic ("cannot downcast weight");
                    self.multiSigManager.configureKeys(pks: [pubKey], kws: [weight])
                case "removeKey":
                    let pubKey = p.getArg(i: 0)! as? String ?? panic ("cannot downcast public key");
                    self.multiSigManager.removeKeys(pks: [pubKey])
                case "transfer":
                    // This combines withdraw + deposit as withdraw cannot ensure that the withdrawmn amount
                    // be deposited at a signers' agreed address
                    let amount = p.getArg(i: 0)! as? UFix64 ?? panic ("cannot downcast amount");
                    let to = p.getArg(i: 1)! as? Address ?? panic ("cannot downcast address");
                    let toAcct = getAccount(to);
                    let receiver = toAcct.getCapability(FiatToken.VaultReceiverPubPath)!
                        .borrow<&{FungibleToken.Receiver}>()
                        ?? panic("Unable to borrow receiver reference for recipient")
                    let v <- self.withdraw(amount: amount);
                    receiver.deposit(from: <- v)
                case "approval":
                    let r = p.getArg(i: 0)! as? UInt64 ?? panic ("cannot downcast resource id");
                    let a = p.getArg(i: 1)! as? UFix64 ?? panic ("cannot downcast amount") 
                    self.approval(resourceId: r, amount: a);
                case "increaseAllowance":
                    let r = p.getArg(i: 0)! as? UInt64 ?? panic ("cannot downcast resource id");
                    let a = p.getArg(i: 1)! as? UFix64 ?? panic ("cannot downcast amount") 
                    self.increaseAllowance(resourceId: r, increment: a);
                case "decreaseAllowance":
                    let r = p.getArg(i: 0)! as? UInt64 ?? panic ("cannot downcast resource id");
                    let a = p.getArg(i: 1)! as? UFix64 ?? panic ("cannot downcast amount") 
                    self.decreaseAllowance(resourceId: r, decrement: a);
                default:
                    panic("Unknown transaction method")
            }
            destroy (p)
            return nil;
        }

        pub fun getTxIndex(): UInt64 {
            return self.multiSigManager.txIndex
        }

        pub fun getSignerKeys(): [String] {
            return self.multiSigManager.getSignerKeys()
        }
        pub fun getSignerKeyAttr(publicKey: String): OnChainMultiSig.PubKeyAttr? {
            return self.multiSigManager.getSignerKeyAttr(publicKey: publicKey)
        }
        
        // ======== OnChainMultiSig.KeyManager interfaces
        // Private (if linked) interfaces to set the keys for the OnChainMultiSig.Manager
        pub fun addKeys( multiSigPubKeys: [String], multiSigKeyWeights: [UFix64]) {
            self.multiSigManager.configureKeys(pks: multiSigPubKeys, kws: multiSigKeyWeights)
        }
        pub fun removeKeys( multiSigPubKeys: [String]) {
            self.multiSigManager.removeKeys(pks: multiSigPubKeys)
        }

        destroy() {
            FiatToken.totalSupply = FiatToken.totalSupply - self.balance
            destroy(self.multiSigManager)
            emit DestroyVault(resourceId: self.uuid);
        }

        // initialize the balance at resource creation time
        init(balance: UFix64) {
            self.balance = balance;
            self.allowed = {};
            self.multiSigManager <-  OnChainMultiSig.createMultiSigManager(publicKeys: [], pubKeyAttrs: [])
        }
        
    }
    
    

    /// The owner is defined in https://github.com/centrehq/centre-tokens/blob/master/doc/tokendesign.md
    ///
    /// Owner of the contract creates these 3 resources when deploying the contract 
    pub resource Owner {

        pub fun createNewPauseExecutor(): @PauseExecutor{
            return <-create PauseExecutor()
        }

        pub fun createNewBlocklistExecutor(): @BlocklistExecutor{
            return <-create BlocklistExecutor()
        }

        pub fun createNewMasterMinter(pk: [String], pka: [OnChainMultiSig.PubKeyAttr]): @MasterMinter{
            return <-create MasterMinter(pk: pk, pka: pka)
        }
    }

    /// The master minter is defined in https://github.com/centrehq/centre-tokens/blob/master/doc/tokendesign.md
    ///
    /// The master minter creates minter controller resources to delegate control for minters
    pub resource MasterMinter: FiatTokenInterface.MasterMinter, ResourceId, OnChainMultiSig.PublicSigner {

        // OnChainMultiSig Manager for storing publickeys, pending payloads, signatures, etc
        access(self) let multiSigManager: @OnChainMultiSig.Manager;

        /// Function to configure MinterController
        pub fun configureMinterController(minter: UInt64, minterController: UInt64) {
            /// we overwrite the key here since minterController can only control 1 minter
            FiatToken.managedMinters.insert(key: minterController, minter);
            emit ControllerConfigured(controller: minterController, minter: minter)
        }
        
        /// Function to remove MinterController
        pub fun removeMinterController(minterController: UInt64){
            pre {
                FiatToken.managedMinters.containsKey(minterController): "cannot remove unknown minter controller"
            }
            FiatToken.managedMinters.remove(key: minterController);
            emit ControllerRemoved(controller: minterController)
        }
        
        // ===== OnChainMultiSig.PublicSigner interfaces
        pub fun addNewPayload(payload: @OnChainMultiSig.PayloadDetails, publicKey: String, sig: [UInt8]) {
            self.multiSigManager.addNewPayload(resourceId: self.uuid, payload: <-payload, publicKey: publicKey, sig: sig);
        }

        pub fun addPayloadSignature (txIndex: UInt64, publicKey: String, sig: [UInt8]) {
            self.multiSigManager.addPayloadSignature(resourceId: self.uuid, txIndex: txIndex, publicKey: publicKey, sig: sig);
       }
        pub fun executeTx(txIndex: UInt64): @AnyResource? {
            let p <- self.multiSigManager.readyForExecution(txIndex: txIndex) ?? panic ("no transactable payload at given txIndex")
            switch p.method {
                case "configureKey":
                    let pubKey = p.getArg(i: 0)! as? String ?? panic ("cannot downcast public key");
                    let weight = p.getArg(i: 1)! as? UFix64 ?? panic ("cannot downcast weight");
                    self.multiSigManager.configureKeys(pks: [pubKey], kws: [weight])
                case "removeKey":
                    let pubKey = p.getArg(i: 0)! as? String ?? panic ("cannot downcast public key");
                    self.multiSigManager.removeKeys(pks: [pubKey])
                case "configureMinterController":
                    let m = p.getArg(i: 0)! as? UInt64 ?? panic ("cannot downcast minter id");
                    let mc = p.getArg(i: 1)! as? UInt64 ?? panic ("cannot downcast minterController id") 
                    self.configureMinterController(minter: m, minterController: mc);
                case "removeMinterController":
                    let mc = p.getArg(i: 0)! as? UInt64 ?? panic ("cannot downcast minterController id");
                    self.removeMinterController(minterController: mc);
                default:
                    panic("Unknown transaction method")
            }
            destroy (p)
            return nil;
        }

        pub fun UUID(): UInt64 {
            return self.uuid;
        }; 

        pub fun getTxIndex(): UInt64 {
            return self.multiSigManager.txIndex
        }

        pub fun getSignerKeys(): [String] {
            return self.multiSigManager.getSignerKeys()
        }
        pub fun getSignerKeyAttr(publicKey: String): OnChainMultiSig.PubKeyAttr? {
            return self.multiSigManager.getSignerKeyAttr(publicKey: publicKey)
        }

        destroy() {
            destroy self.multiSigManager
        }

        init(pk: [String], pka: [OnChainMultiSig.PubKeyAttr]) {
            self.multiSigManager <-  OnChainMultiSig.createMultiSigManager(publicKeys: pk, pubKeyAttrs: pka)
        }
    }
    
    /// This is a resource to manage minters, delegated from MasterMinter
    /// https://github.com/centrehq/centre-tokens/blob/master/doc/masterminter.md#interaction-with-fiattoken-contract
    pub resource MinterController: FiatTokenInterface.MinterController, ResourceId, OnChainMultiSig.PublicSigner  {

        // OnChainMultiSig Manager for storing publickeys, pending payloads, signatures, etc
        access(self) let multiSigManager: @OnChainMultiSig.Manager;

        pub fun UUID(): UInt64 {
            return self.uuid;
        }

        /// Function that updates existing minter restrictions
        pub fun configureMinterAllowance(allowance: UFix64) {
            let managedMinter = FiatToken.managedMinters[self.uuid] ?? panic("controller does not manage any minters");
            FiatToken.minterAllowances[managedMinter] = allowance;
            emit MinterConfigured(controller: self.uuid, minter: managedMinter, allowance: allowance);
        }
        
        /// Function that increase existing minter allowance 
        pub fun increaseMinterAllowance(increment: UFix64) {
            let managedMinter = FiatToken.managedMinters[self.uuid] ?? panic("controller does not manage any minters");
            let allowance = FiatToken.minterAllowances[managedMinter] ?? 0.0;
            let newAllowance = allowance.saturatingAdd(increment);
            self.configureMinterAllowance(allowance: newAllowance);
        }

        /// Function that decrease existing minter allowance 
        pub fun decreaseMinterAllowance(decrement: UFix64) {
            let managedMinter = FiatToken.managedMinters[self.uuid] ?? panic("controller does not manage any minters");

            // If there is no allowance already, we cannot decrease it
            let allowance = FiatToken.minterAllowances[managedMinter] ?? panic("Cannot decrease nil mint allowance");

            let newAllowance = allowance!.saturatingSubtract(decrement);
            self.configureMinterAllowance(allowance: newAllowance);
        }
        
        /// Function to remove minter
        pub fun removeMinter(){
            let managedMinter = FiatToken.managedMinters[self.uuid] ?? panic("controller does not manage any minters");
            assert(FiatToken.minterAllowances.containsKey(managedMinter), message: "cannot remove unknown minter");
            FiatToken.minterAllowances.remove(key: managedMinter);
            emit MinterRemoved(controller: self.uuid, minter: managedMinter)
        }
        
        // OnChainMultiSig.PublicSigner interfaces
        pub fun addNewPayload(payload: @OnChainMultiSig.PayloadDetails, publicKey: String, sig: [UInt8]) {
            self.multiSigManager.addNewPayload(resourceId: self.uuid, payload: <-payload, publicKey: publicKey, sig: sig);
        }

        pub fun addPayloadSignature (txIndex: UInt64, publicKey: String, sig: [UInt8]) {
            self.multiSigManager.addPayloadSignature(resourceId: self.uuid, txIndex: txIndex, publicKey: publicKey, sig: sig);
       }
        pub fun executeTx(txIndex: UInt64): @AnyResource? {
            let p <- self.multiSigManager.readyForExecution(txIndex: txIndex) ?? panic ("no transactable payload at given txIndex")
            switch p.method {
                case "configureKey":
                    let pubKey = p.getArg(i: 0)! as? String ?? panic ("cannot downcast public key");
                    let weight = p.getArg(i: 1)! as? UFix64 ?? panic ("cannot downcast weight");
                    self.multiSigManager.configureKeys(pks: [pubKey], kws: [weight])
                case "removeKey":
                    let pubKey = p.getArg(i: 0)! as? String ?? panic ("cannot downcast public key");
                    self.multiSigManager.removeKeys(pks: [pubKey])
                case "configureMinterAllowance":
                    let allowance = p.getArg(i: 0)! as? UFix64 ?? panic ("cannot downcast allowance");
                    self.configureMinterAllowance(allowance: allowance);
                case "increaseMinterAllowance":
                    let increment = p.getArg(i: 0)! as? UFix64 ?? panic ("cannot downcast increment");
                    self.increaseMinterAllowance(increment: increment);
                case "decreaseMinterAllowance":
                    let decrement = p.getArg(i: 0)! as? UFix64 ?? panic ("cannot downcast decrement");
                    self.decreaseMinterAllowance(decrement: decrement);
                case "removeMinter":
                    self.removeMinter();
                default:
                    panic("Unknown transaction method")
            }
            destroy (p)
            return nil;
        }

        pub fun getTxIndex(): UInt64 {
            return self.multiSigManager.txIndex
        }

        pub fun getSignerKeys(): [String] {
            return self.multiSigManager.getSignerKeys()
        }
        pub fun getSignerKeyAttr(publicKey: String): OnChainMultiSig.PubKeyAttr? {
            return self.multiSigManager.getSignerKeyAttr(publicKey: publicKey)
        }

        destroy() {
            destroy self.multiSigManager
        }

        init(pk: [String], pka: [OnChainMultiSig.PubKeyAttr]) {
            self.multiSigManager <-  OnChainMultiSig.createMultiSigManager(publicKeys: pk, pubKeyAttrs: pka)
        }
    }

    /// The actual minter resource, the resourceId must be added to the `minterAllowances` list
    /// for minter to successfully mint / burn within restrictions
    pub resource Minter: FiatTokenInterface.Minter, ResourceId, OnChainMultiSig.PublicSigner {
        
        // OnChainMultiSig Manager for storing publickeys, pending payloads, signatures, etc
        access(self) let multiSigManager: @OnChainMultiSig.Manager;

        pub fun UUID(): UInt64 {
            return self.uuid
        }

        pub fun mint(amount: UFix64): @FungibleToken.Vault{
            pre {
                !FiatToken.paused: "FiatToken contract paused" 
                FiatToken.blocklist[self.uuid] == nil: "Minter Blocklisted"
                FiatToken.minterAllowances.containsKey(self.uuid): "minter does not have allowance set"
            }
            let mintAllowance = FiatToken.minterAllowances[self.uuid]!;
            assert(mintAllowance >= amount, message: "insufficient mint allowance");
            FiatToken.minterAllowances.insert(key: self.uuid, mintAllowance - amount);
            let newTotalSupply = FiatToken.totalSupply + amount;
            FiatToken.totalSupply = newTotalSupply;

            emit Mint(minter: self.uuid, amount: amount);
            return <-create Vault(balance: amount);
        }
        
        /// Burn tokens called by minter reduces the totalSupply of the tokens
        /// Burning tokens does not increase minting allowance
        // https://github.com/centrehq/centre-tokens/blob/master/doc/tokendesign.md#burning
        pub fun burn(vault: @FungibleToken.Vault) {
            pre {
                !FiatToken.paused: "FiatToken contract paused" 
                FiatToken.blocklist[self.uuid] == nil: "Minter Blocklisted"
                FiatToken.minterAllowances.containsKey(self.uuid): "minter is not configured"
            }
            let amount = vault.balance;
            assert(FiatToken.totalSupply >= amount, message: "burning more than total supply");

            // destroy vault method handles updates to the total supply
            destroy vault;

            emit Burn(minter: self.uuid, amount: amount);
        }

        // OnChainMultiSig.PublicSigner interfaces 
        pub fun addNewPayload(payload: @OnChainMultiSig.PayloadDetails, publicKey: String, sig: [UInt8]) {
            self.multiSigManager.addNewPayload(resourceId: self.uuid, payload: <- payload, publicKey: publicKey, sig: sig);
        }

        pub fun addPayloadSignature (txIndex: UInt64, publicKey: String, sig: [UInt8]) {
            self.multiSigManager.addPayloadSignature(resourceId: self.uuid, txIndex: txIndex, publicKey: publicKey, sig: sig);
        }
        pub fun executeTx(txIndex: UInt64): @AnyResource? {
            let p <- self.multiSigManager.readyForExecution(txIndex: txIndex) ?? panic ("no transactable payload at given txIndex")
            switch p.method {
                case "configureKey":
                    let pubKey = p.getArg(i: 0)! as? String ?? panic ("cannot downcast public key");
                    let weight = p.getArg(i: 1)! as? UFix64 ?? panic ("cannot downcast weight");
                    self.multiSigManager.configureKeys(pks: [pubKey], kws: [weight]);
                case "removeKey":
                    let pubKey = p.getArg(i: 0)! as? String ?? panic ("cannot downcast public key");
                    self.multiSigManager.removeKeys(pks: [pubKey]);
                case "removePayload":
                    // This helps to retrieve the Vault added to burn in case signers change their minds
                    let txIndex = p.getArg(i: 0)! as? UInt64 ?? panic ("cannot downcast txIndex");
                    let payloadToRemove <- self.multiSigManager.removePayload(txIndex: txIndex);
                    var temp: @AnyResource? <- nil;
                    payloadToRemove.rsc <-> temp;
                    destroy(p);
                    destroy(payloadToRemove);
                    return <- temp;
                case "mintTo":
                    // This replaces Mint because Mint does not enforced minted amount should deposit to 
                    // certain account that multisig signers can be sure of
                    let amount = p.getArg(i: 0)! as? UFix64 ?? panic ("cannot downcast amount");
                    let recvAddress = p.getArg(i: 1)! as? Address ?? panic ("cannot downcast address");
                    let recvAcct = getAccount(recvAddress);
                    let recv = recvAcct.getCapability(FiatToken.VaultReceiverPubPath)!
                        .borrow<&{FungibleToken.Receiver}>()
                        ?? panic("Unable to borrow receiver reference for recipient");
                    let v <- self.mint(amount: amount);
                    recv.deposit(from: <-v);
                case "burn":
                    var temp: @AnyResource? <- nil;
                    p.rsc <-> temp;
                    let vault <- temp! as! @FungibleToken.Vault;
                    self.burn(vault: <- vault);
                default:
                    panic("Unknown transaction method");
            }
            destroy(p);
            return nil;
        }

        pub fun getTxIndex(): UInt64 {
            return self.multiSigManager.txIndex
        }

        pub fun getSignerKeys(): [String] {
            return self.multiSigManager.getSignerKeys()
        }
        pub fun getSignerKeyAttr(publicKey: String): OnChainMultiSig.PubKeyAttr? {
            return self.multiSigManager.getSignerKeyAttr(publicKey: publicKey)
        }

        destroy() {
            destroy self.multiSigManager
        }

        init(pk: [String], pka: [OnChainMultiSig.PubKeyAttr]) {
            self.multiSigManager <-  OnChainMultiSig.createMultiSigManager(publicKeys: pk, pubKeyAttrs: pka)
        }
    }

    /// Note: `PauseExecutor` and `BlocklistExeuctor` do not support multisig as they themselves do not do any transactions.
    /// Once the capability has been shared to `Pauser` and `Blocklister` respectively, those resources calls 
    /// for the state change transactions 
    ///
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

    /// Delegate blocklister for actually adding resources to blocklist
    //  Blocklisting is not paused in the event the contract is paused\
    // https://github.com/centrehq/centre-tokens/blob/master/doc/tokendesign.md#pausing
    pub resource Blocklister: BlocklistCapReceiver, OnChainMultiSig.PublicSigner {
        // Optional value, initially nil until set by BlocklistExecutor
        access(self) var blocklistcap: Capability<&BlocklistExecutor>?;
        
        // OnChainMultiSig Manager for storing publickeys, pending payloads, signatures, etc
        access(self) let multiSigManager: @OnChainMultiSig.Manager;

        pub fun blocklist(resourceId: UInt64){
            post {
                FiatToken.blocklist.containsKey(resourceId): "Resource not blocklisted"
            }
            self.blocklistcap!.borrow()!.blocklist(resourceId: resourceId);
        };

        pub fun unblocklist(resourceId: UInt64){
            post {
                !FiatToken.blocklist.containsKey(resourceId): "Resource still on blocklist"
            }
            self.blocklistcap!.borrow()!.unblocklist(resourceId: resourceId);
        };
        
        // Called by the Account that owns BlocklistExecutor
        // (since they are the only account that can create such Capability as input arg)
        // This means the BlocklistExector account "grants" the right to call fn in BlocklistExecutor 
        // 
        // The Account that owns BlocklistExector will be set in init() of the contract and will be the Owner/Admin
        pub fun setBlocklistCap(blocklistCap: Capability<&BlocklistExecutor>){
            pre {
                blocklistCap.borrow() != nil: "Invalid BlocklistCap capability"
            }
            self.blocklistcap = blocklistCap;
        }
        
        // OnChainMultiSig.PublicSigner interfaces 
        pub fun addNewPayload(payload: @OnChainMultiSig.PayloadDetails, publicKey: String, sig: [UInt8]) {
            self.multiSigManager.addNewPayload(resourceId: self.uuid, payload: <- payload, publicKey: publicKey, sig: sig);
        }

        pub fun addPayloadSignature (txIndex: UInt64, publicKey: String, sig: [UInt8]) {
            self.multiSigManager.addPayloadSignature(resourceId: self.uuid, txIndex: txIndex, publicKey: publicKey, sig: sig);
        }

        pub fun executeTx(txIndex: UInt64): @AnyResource? {
            let p <- self.multiSigManager.readyForExecution(txIndex: txIndex) ?? panic ("no transactable payload at given txIndex")
            switch p.method {
                case "configureKey":
                    let pubKey = p.getArg(i: 0)! as? String ?? panic ("cannot downcast public key");
                    let weight = p.getArg(i: 1)! as? UFix64 ?? panic ("cannot downcast weight");
                    self.multiSigManager.configureKeys(pks: [pubKey], kws: [weight]);
                case "removeKey":
                    let pubKey = p.getArg(i: 0)! as? String ?? panic ("cannot downcast public key");
                    self.multiSigManager.removeKeys(pks: [pubKey]);
                case "blocklist":
                    let resourceId = p.getArg(i: 0)! as? UInt64 ?? panic ("cannot downcast resourceId");
                    self.blocklist(resourceId: resourceId)
                case "unblocklist":
                    let resourceId = p.getArg(i: 0)! as? UInt64 ?? panic ("cannot downcast resourceId");
                    self.unblocklist(resourceId: resourceId)
                default:
                    panic("Unknown transaction method");
            }
            destroy(p);
            return nil;
        }

        pub fun UUID(): UInt64 {
            return self.uuid;
        }

        pub fun getTxIndex(): UInt64 {
            return self.multiSigManager.txIndex
        }

        pub fun getSignerKeys(): [String] {
            return self.multiSigManager.getSignerKeys()
        }
        pub fun getSignerKeyAttr(publicKey: String): OnChainMultiSig.PubKeyAttr? {
            return self.multiSigManager.getSignerKeyAttr(publicKey: publicKey)
        }

        destroy() {
            destroy self.multiSigManager
        }

        init(pk: [String], pka: [OnChainMultiSig.PubKeyAttr]) {
            self.blocklistcap = nil;
            self.multiSigManager <-  OnChainMultiSig.createMultiSigManager(publicKeys: pk, pubKeyAttrs: pka)
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

    /// Delegate pauser 
    pub resource Pauser: PauseCapReceiver, OnChainMultiSig.PublicSigner {
        // This will be a Capability from the PauseExecutor created by the Owner and linked privately.
        // Owner will call setPauseCapability to provide it.
        access(self) var pauseCap:  Capability<&PauseExecutor>?;
        
        // OnChainMultiSig Manager for storing publickeys, pending payloads, signatures, etc
        access(self) let multiSigManager: @OnChainMultiSig.Manager;
        
        // Called by the Account that owns PauseExecutor
        // (since they are the only account that can create such Capability as input arg)
        // This means the PauseExector account "grants" the right to call fn in pauseExecutor
        // 
        // The Account that owns PauseExecutor will be set in init() of the contract and will be the Owner/Admin
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

        // OnChainMultiSig.PublicSigner interfaces 
        pub fun addNewPayload(payload: @OnChainMultiSig.PayloadDetails, publicKey: String, sig: [UInt8]) {
            self.multiSigManager.addNewPayload(resourceId: self.uuid, payload: <- payload, publicKey: publicKey, sig: sig);
        }

        pub fun addPayloadSignature (txIndex: UInt64, publicKey: String, sig: [UInt8]) {
            self.multiSigManager.addPayloadSignature(resourceId: self.uuid, txIndex: txIndex, publicKey: publicKey, sig: sig);
        }

        pub fun executeTx(txIndex: UInt64): @AnyResource? {
            let p <- self.multiSigManager.readyForExecution(txIndex: txIndex) ?? panic ("no transactable payload at given txIndex")
            switch p.method {
                case "configureKey":
                    let pubKey = p.getArg(i: 0)! as? String ?? panic ("cannot downcast public key");
                    let weight = p.getArg(i: 1)! as? UFix64 ?? panic ("cannot downcast weight");
                    self.multiSigManager.configureKeys(pks: [pubKey], kws: [weight]);
                case "removeKey":
                    let pubKey = p.getArg(i: 0)! as? String ?? panic ("cannot downcast public key");
                    self.multiSigManager.removeKeys(pks: [pubKey]);
                case "pause":
                    self.pause()
                case "unpause":
                    self.unpause()
                default:
                    panic("Unknown transaction method");
            }
            destroy(p);
            return nil;
        }

        pub fun UUID(): UInt64 {
            return self.uuid;
        }

        pub fun getTxIndex(): UInt64 {
            return self.multiSigManager.txIndex
        }

        pub fun getSignerKeys(): [String] {
            return self.multiSigManager.getSignerKeys()
        }
        pub fun getSignerKeyAttr(publicKey: String): OnChainMultiSig.PubKeyAttr? {
            return self.multiSigManager.getSignerKeyAttr(publicKey: publicKey)
        }

        destroy() {
            destroy self.multiSigManager
        }

        init(pk: [String], pka: [OnChainMultiSig.PubKeyAttr]) {
            self.pauseCap = nil;
            self.multiSigManager <-  OnChainMultiSig.createMultiSigManager(publicKeys: pk, pubKeyAttrs: pka)
        }
    }

    // ============ FiatToken Methods ==============

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

    pub fun createNewPauser(publicKeys: [String], pubKeyAttrs: [OnChainMultiSig.PubKeyAttr]): @Pauser{
        let pauser <-create Pauser(pk: publicKeys, pka: pubKeyAttrs)
        emit PauserCreated(resourceId: pauser.uuid);
        return <- pauser
    }

    pub fun createNewMinterController(publicKeys: [String], pubKeyAttrs: [OnChainMultiSig.PubKeyAttr]): @MinterController{
        let minterController <- create MinterController(pk: publicKeys, pka: pubKeyAttrs)
        emit MinterControllerCreated(resourceId: minterController.uuid);
        return <- minterController
    }

    pub fun createNewMinter(publicKeys: [String], pubKeyAttrs: [OnChainMultiSig.PubKeyAttr]): @Minter{
        let minter <- create Minter(pk: publicKeys, pka: pubKeyAttrs);
        emit MinterCreated(resourceId: minter.uuid);
        return <- minter
    }

    pub fun createNewBlocklister(publicKeys: [String], pubKeyAttrs: [OnChainMultiSig.PubKeyAttr]): @Blocklister{
        let blocklister <-create Blocklister(pk: publicKeys, pka: pubKeyAttrs)
        emit BlocklisterCreated(resourceId: blocklister.uuid);
        return <-blocklister
    }

    pub fun getBlocklist(resourceId: UInt64): UInt64?{
        return FiatToken.blocklist[resourceId]
    }

    pub fun getManagedMinter(resourceId: UInt64): UInt64?{
        return FiatToken.managedMinters[resourceId]
    }
    pub fun getMinterAllowance(resourceId: UInt64): UFix64?{
        return FiatToken.minterAllowances[resourceId]
    }
    
    // ============ FiatToken Initializer ==============
    init(
        adminAccount: AuthAccount, 
        VaultStoragePath: StoragePath,
        VaultBalancePubPath: PublicPath,
        VaultUUIDPubPath: PublicPath,
        VaultAllowancePubPath: PublicPath,
        VaultReceiverPubPath: PublicPath,
        VaultPubSigner: PublicPath,
        BlocklistExecutorStoragePath: StoragePath,
        BlocklistExecutorPrivPath: PrivatePath,
        BlocklisterStoragePath: StoragePath,
        BlocklisterCapReceiverPubPath: PublicPath,
        BlocklisterPubSigner: PublicPath,
        PauseExecutorStoragePath: StoragePath,
        PauseExecutorPrivPath: PrivatePath,
        PauserStoragePath: StoragePath,
        PauserCapReceiverPubPath: PublicPath,
        PauserPubSigner: PublicPath,
        OwnerStoragePath: StoragePath,
        OwnerPrivPath: PrivatePath,
        MasterMinterStoragePath: StoragePath,
        MasterMinterPrivPath: PrivatePath,
        MasterMinterPubSigner: PublicPath,
        MasterMinterUUIDPubPath: PublicPath,
        MinterControllerStoragePath: StoragePath,
        MinterControllerUUIDPubPath: PublicPath,
        MinterControllerPubSigner: PublicPath,
        MinterStoragePath: StoragePath,
        MinterUUIDPubPath: PublicPath,
        MinterPubSigner: PublicPath,
        tokenName: String,
        version: String,
        initTotalSupply: UFix64,
        initPaused: Bool, 
        ownerAccountPubKeys: [String],
        ownerAccountKeyWeights: [UFix64],
    ) {

        // These keys and weights are used to initialise the `MasterMinter` owned by the owner
        assert(ownerAccountPubKeys.length == ownerAccountKeyWeights.length, message: "pubkey length and weights length mismatched");

        self.name = tokenName;
        self.version = version;
        self.paused = initPaused;
        self.totalSupply = initTotalSupply;
        self.blocklist = {};
        self.minterAllowances = {};
        self.managedMinters = {};

        self.VaultStoragePath = VaultStoragePath;
        self.VaultBalancePubPath = VaultBalancePubPath;
        self.VaultUUIDPubPath = VaultUUIDPubPath;
        self.VaultAllowancePubPath = VaultAllowancePubPath;
        self.VaultReceiverPubPath = VaultReceiverPubPath;
        self.VaultPubSigner = VaultPubSigner;

        self.BlocklistExecutorStoragePath =  BlocklistExecutorStoragePath;
        self.BlocklistExecutorPrivPath = BlocklistExecutorPrivPath;

        self.BlocklisterStoragePath =  BlocklisterStoragePath;
        self.BlocklisterCapReceiverPubPath = BlocklisterCapReceiverPubPath;
        self.BlocklisterPubSigner = BlocklisterPubSigner;

        self.PauseExecutorStoragePath = PauseExecutorStoragePath; 
        self.PauseExecutorPrivPath = PauseExecutorPrivPath;

        self.PauserStoragePath = PauseExecutorStoragePath; 
        self.PauserCapReceiverPubPath = PauserCapReceiverPubPath;
        self.PauserPubSigner = PauserPubSigner;

        self.OwnerStoragePath = OwnerStoragePath;
        self.OwnerPrivPath = OwnerPrivPath;

        self.MasterMinterStoragePath = MasterMinterStoragePath;
        self.MasterMinterPrivPath = MasterMinterPrivPath;
        self.MasterMinterPubSigner = MasterMinterPubSigner;
        self.MasterMinterUUIDPubPath = MasterMinterUUIDPubPath;

        self.MinterControllerStoragePath = MinterControllerStoragePath;
        self.MinterControllerUUIDPubPath = MinterControllerUUIDPubPath;
        self.MinterControllerPubSigner = MinterControllerPubSigner;

        self.MinterStoragePath = MinterStoragePath;
        self.MinterUUIDPubPath = MinterUUIDPubPath;
        self.MinterPubSigner = MinterPubSigner;

        // Create the Vault with the total supply of tokens and save it in storage
        //
        let vault <- create Vault(balance: self.totalSupply)
        self.account.save(<-vault, to: self.VaultStoragePath)

        // Create a public capability to the stored Vault for Reciever, Balance, VaultUUID and withdrawAllowance 
        //
        adminAccount.link<&FiatToken.Vault{FungibleToken.Receiver}>(self.VaultReceiverPubPath, target: self.VaultStoragePath)
        adminAccount.link<&FiatToken.Vault{FungibleToken.Balance}>(self.VaultBalancePubPath, target: self.VaultStoragePath)
        adminAccount.link<&FiatToken.Vault{FiatToken.ResourceId}>(self.VaultUUIDPubPath, target: self.VaultStoragePath)
        adminAccount.link<&FiatToken.Vault{FiatTokenInterface.Allowance}>(self.VaultAllowancePubPath, target: self.VaultStoragePath)
        adminAccount.link<&FiatToken.Vault{OnChainMultiSig.PublicSigner}>(self.VaultPubSigner, target: self.VaultStoragePath)

        // Note: the account deploying this contract can upgrade the contract, aka the admin role in the token design doc
        // Saving the owner here means the admin and the owner is under management of the same account
        let owner <- create Owner();
        adminAccount.save(<-owner, to: self.OwnerStoragePath);
        adminAccount.link<&Owner>(self.OwnerPrivPath, target: self.OwnerStoragePath);
        

        // Create all the owner resources where capabilities can be shared.
        let ownerCap = adminAccount.getCapability<&Owner>(self.OwnerPrivPath);
        
        let pubKeyAttrs: [OnChainMultiSig.PubKeyAttr] = [];
        var i = 0;
        while i < ownerAccountPubKeys.length {
            let pka = OnChainMultiSig.PubKeyAttr(sa: 1, w:  ownerAccountKeyWeights[i]);
            pubKeyAttrs.append(pka);
            i = i + 1;
        }
        
        adminAccount.save(<-ownerCap.borrow()!.createNewPauseExecutor(), to: self.PauseExecutorStoragePath);
        adminAccount.save(<-ownerCap.borrow()!.createNewBlocklistExecutor(), to: self.BlocklistExecutorStoragePath);
        adminAccount.save(<-ownerCap.borrow()!.createNewMasterMinter(pk: ownerAccountPubKeys, pka: pubKeyAttrs), to: self.MasterMinterStoragePath);
        
        adminAccount.link<&PauseExecutor>(self.PauseExecutorPrivPath, target: self.PauseExecutorStoragePath);
        adminAccount.link<&BlocklistExecutor>(self.BlocklistExecutorPrivPath, target: self.BlocklistExecutorStoragePath);
        adminAccount.link<&MasterMinter>(self.MasterMinterPrivPath, target: self.MasterMinterStoragePath);
        adminAccount.link<&MasterMinter{OnChainMultiSig.PublicSigner}>(self.MasterMinterPubSigner, target: self.MasterMinterStoragePath);
        adminAccount.link<&MasterMinter{ResourceId}>(self.MasterMinterUUIDPubPath, target: self.MasterMinterStoragePath);

        // Emit an event that shows that the contract was initialized
        //
        emit TokensInitialized(initialSupply: self.totalSupply)

    }
} 
 
