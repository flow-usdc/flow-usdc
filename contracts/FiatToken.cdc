import Crypto
import "FungibleToken"
import "FungibleTokenMetadataViews"
import "MetadataViews"
import "OnChainMultiSig"
import "IBridgePermissions"

access(all) contract FiatToken: FungibleToken {
	
	// ------- FiatToken Events -------
	
	// Admin events	
	access(all) event AdminCreated(resourceId: UInt64)
	access(all) event AdminChanged(address: Address, resourceId: UInt64)
	
	// Owner events
	access(all) event OwnerCreated(resourceId: UInt64)
	access(all) event OwnerChanged(address: Address, resourceId: UInt64)
	
	// MasterMinter events
	access(all) event MasterMinterCreated(resourceId: UInt64)
	access(all) event MasterMinterChanged(address: Address, resourceId: UInt64)
	
	// Pauser events
	access(all) event Paused()
	access(all) event Unpaused()
	access(all) event PauserCreated(resourceId: UInt64)
	access(all) event PauserChanged(address: Address, resourceId: UInt64)
	
	// Blocklister events
	access(all) event Blocklisted(resourceId: UInt64)
	access(all) event Unblocklisted(resourceId: UInt64)
	access(all) event BlocklisterCreated(resourceId: UInt64)
	access(all) event BlocklisterChanged(address: Address, resourceId: UInt64)
	
	// FiatToken.Vault events
	access(all) event NewVault(resourceId: UInt64)
	access(all) event DestroyVault(resourceId: UInt64)
	access(all) event FiatTokenWithdrawn(amount: UFix64, from: UInt64)
	access(all) event FiatTokenDeposited(amount: UFix64, to: UInt64)
	
	// Minting events
	access(all) event MinterCreated(resourceId: UInt64)
	access(all) event MinterControllerCreated(resourceId: UInt64)
	access(all) event Mint(minter: UInt64, amount: UFix64)
	access(all) event Burn(minter: UInt64, amount: UFix64)
	access(all) event MinterConfigured(controller: UInt64, minter: UInt64, allowance: UFix64)
	access(all)	event MinterRemoved(controller: UInt64, minter: UInt64)
	
	access(all)	event ControllerConfigured(controller: UInt64, minter: UInt64)
	access(all)	event ControllerRemoved(controller: UInt64)

	// ------- FungibleToken Events -------
	access(all)	event TokensWithdrawn(amount: UFix64, from: Address?)
	access(all)	event TokensDeposited(amount: UFix64, to: Address?)
	
	// ------- FiatToken Paths -------
	access(all)	let VaultStoragePath: StoragePath
	access(all)	let VaultBalancePubPath: PublicPath
	access(all)	let VaultUUIDPubPath: PublicPath
	access(all)	let VaultReceiverPubPath: PublicPath
	access(all)	let BlocklistExecutorStoragePath: StoragePath
	access(all)	let BlocklisterStoragePath: StoragePath
	access(all)	let BlocklisterCapReceiverPubPath: PublicPath
	access(all)	let BlocklisterUUIDPubPath: PublicPath
	access(all)	let BlocklisterPubSigner: PublicPath
	access(all)	let PauseExecutorStoragePath: StoragePath
	access(all)	let PauserStoragePath: StoragePath
	access(all)	let PauserCapReceiverPubPath: PublicPath
	access(all)	let PauserUUIDPubPath: PublicPath
	access(all)	let PauserPubSigner: PublicPath
	access(all)	let AdminExecutorStoragePath: StoragePath
	access(all)	let AdminStoragePath: StoragePath
	access(all)	let AdminCapReceiverPubPath: PublicPath
	access(all)	let AdminUUIDPubPath: PublicPath
	access(all)	let AdminPubSigner: PublicPath
	access(all)	let OwnerExecutorStoragePath: StoragePath
	access(all)	let OwnerStoragePath: StoragePath
	access(all)	let OwnerCapReceiverPubPath: PublicPath
	access(all)	let OwnerUUIDPubPath: PublicPath
	access(all)	let OwnerPubSigner: PublicPath
	access(all)	let MasterMinterExecutorStoragePath: StoragePath
	access(all)	let MasterMinterStoragePath: StoragePath
	access(all)	let MasterMinterCapReceiverPubPath: PublicPath
	access(all)	let MasterMinterUUIDPubPath: PublicPath
	access(all)	let MasterMinterPubSigner: PublicPath
	access(all)	let MinterControllerStoragePath: StoragePath
	access(all)	let MinterControllerUUIDPubPath: PublicPath
	access(all)	let MinterControllerPubSigner: PublicPath
	access(all)	let MinterStoragePath: StoragePath
	access(all)	let MinterUUIDPubPath: PublicPath
	
	// ------- FiatToken States / Variables -------
	access(all)	let name: String
	
	access(all)	var version: String
	
	// Set to true if the contract is paused
	access(all)	var paused: Bool
	
	// The token total supply
	access(all)	var totalSupply: UFix64
	
	// Blocked resources dictionary {resourceId: Block Height}
	access(contract) let blocklist: {UInt64: UInt64}
	
	// Managed minters dictionary {MinterController: Minter}
	access(contract) let managedMinters: {UInt64: UInt64}
	
	// Minter allowance dictionary {Minter: Allowance}
	access(contract) let minterAllowances: {UInt64: UFix64}
	
	// ------- FiatToken Interfaces  -------
	access(all)	resource interface ResourceId { 
		access(all) view fun UUID(): UInt64 {
            return self.uuid
        }
	}

    access(all) resource interface MultiSigManagerDefaultImpl {
        access(OnChainMultiSig.Owner) let multiSigManager: @OnChainMultiSig.Manager

        access(all) fun addNewPayload(payload: @OnChainMultiSig.PayloadDetails, publicKey: String, sig: [UInt8]) { 
			self.multiSigManager.addNewPayload(resourceId: self.uuid, payload: <-payload, publicKey: publicKey, sig: sig)
		}
        access(all) fun addPayloadSignature (txIndex: UInt64, publicKey: String, sig: [UInt8]) { 
			self.multiSigManager.addPayloadSignature(resourceId: self.uuid, txIndex: txIndex, publicKey: publicKey, sig: sig)
		}
        access(all) view fun getTxIndex(): UInt64 { 
			return self.multiSigManager.txIndex
		}
        access(all) fun getSignerKeys(): [String] { 
			return self.multiSigManager.getSignerKeys()
		}
        access(all) fun getSignerKeyAttr(publicKey: String): OnChainMultiSig.PubKeyAttr? { 
			return self.multiSigManager.getSignerKeyAttr(publicKey: publicKey)
		}
    }
	
	access(all)	resource interface AdminCapReceiver { 
		access(all) fun setAdminCap(cap: Capability<&FiatToken.AdminExecutor>): Void
	}
	
	access(all)	resource interface OwnerCapReceiver { 
		access(all) fun setOwnerCap(cap: Capability<&FiatToken.OwnerExecutor>): Void
	}
	
	access(all)	resource interface MasterMinterCapReceiver { 
		access(all) fun setMasterMinterCap(cap: Capability<&FiatToken.MasterMinterExecutor>): Void
	}
	
	access(all)	resource interface BlocklisterCapReceiver { 
		access(all) fun setBlocklistCap(cap: Capability<&FiatToken.BlocklistExecutor>): Void
	}
	
	access(all)	resource interface PauseCapReceiver { 
		access(all) fun setPauseCap(cap: Capability<&FiatToken.PauseExecutor>): Void
	}
	
	// ------- Capability Destruction -------
	access(contract) fun unlinkPrivateCapabilities(_ storagePath: StoragePath) {
        // Iterate through FiatToken account capability controllers
        // for the specified storage path and delete them
        // so a new one can be created
        // Private Paths do not exist any more in Cadence
        // so we use capability controllers now
        let controllers = self.account.capabilities.storage.getControllers(forPath: storagePath)
        for controller in controllers {
            controller.delete()
        }
    }
	
	// ------- FiatToken Resources -------
	access(all) resource Vault: ResourceId, FungibleToken.Vault {

		access(all)	var balance: UFix64

        /// Called when a fungible token is burned via the `Burner.burn()` method
        access(contract) fun burnCallback() {
            pre { 
				!FiatToken.paused:
					"Cannot burn USDC while the FiatToken contract is paused"
				FiatToken.blocklist[self.uuid] == nil:
					"Cannot burn USDC while the owner's Vault is Blocklisted"
			}
            if self.balance > 0.0 {
                FiatToken.totalSupply = FiatToken.totalSupply - self.balance
            }
            self.balance = 0.0
        }

        access(all) view fun getViews(): [Type] {
            return FiatToken.getContractViews(resourceType: nil)
        }

        access(all) fun resolveView(_ view: Type): AnyStruct? {
            return FiatToken.resolveContractView(resourceType: nil, viewType: view)
        }

        /// getSupportedVaultTypes optionally returns a list of vault types that this receiver accepts
        access(all) view fun getSupportedVaultTypes(): {Type: Bool} {
            let supportedTypes: {Type: Bool} = {}
            supportedTypes[self.getType()] = true
            return supportedTypes
        }

        /// Returns whether the specified type can be deposited
        access(all) view fun isSupportedVaultType(type: Type): Bool {
            return self.getSupportedVaultTypes()[type] ?? false
        }

        /// Asks if the amount can be withdrawn from this vault
        access(all) view fun isAvailableToWithdraw(amount: UFix64): Bool {
            return amount <= self.balance
        }
		
		access(FungibleToken.Withdraw) fun withdraw(amount: UFix64): @{FungibleToken.Vault} {
			pre { 
				!FiatToken.paused:
					"Cannot withdraw USDC while the FiatToken contract is paused"
				FiatToken.blocklist[self.uuid] == nil:
					"Cannot withdraw USDC while the owner's Vault is Blocklisted"
			}
			self.balance = self.balance - amount
			emit FiatTokenWithdrawn(amount: amount, from: self.uuid)
			emit TokensWithdrawn(amount: amount, from: self.owner?.address)
			return <-create Vault(balance: amount)
		}
		
		access(all)	fun deposit(from: @{FungibleToken.Vault}): Void { 
			pre{ 
				!FiatToken.paused:
					"Cannot deposit USDC while the FiatToken contract is paused"
				FiatToken.blocklist[from.uuid] == nil:
					"Cannot deposit USDC while the deposited Vault is Blocklisted"
				FiatToken.blocklist[self.uuid] == nil:
					"Cannot deposit USDC while the receiving Vault is Blocklisted"
			}
			let vault <- from as! @FiatToken.Vault
			self.balance = self.balance + vault.balance
			emit FiatTokenDeposited(amount: vault.balance, to: self.uuid)
			emit TokensDeposited(amount: vault.balance, to: self.owner?.address)
			destroy vault
		}
		
		access(all)	fun createEmptyVault(): @{FungibleToken.Vault} { 
			return <-create Vault(balance: 0.0)
		}
		
		init(balance: UFix64) { 
			self.balance = balance
		}
	}
	
    /// Resource that lives in the FiatToken account
    /// that performs the explicit Admin actions
    /// after a successful on chain multisig has routed a call to it
    /// from the Admin resource
	access(all)	resource AdminExecutor {
		
		access(all) fun upgradeContract(name: String, code: [UInt8], version: String) { 
			FiatToken.upgradeContract(name: name, code: code, version: version)
		}
		
        /// Revokes access to all existing AdminExecutor capabilities
        /// and assigns a new AdminExecutor capability to a new account
		access(all) fun changeAdmin(to: Address) { 

			FiatToken.unlinkPrivateCapabilities(FiatToken.AdminExecutorStoragePath)

			let newCap = FiatToken.account.capabilities.storage.issue<&AdminExecutor>(FiatToken.AdminExecutorStoragePath)

			let receiver = getAccount(to).capabilities.get<&Admin>(FiatToken.AdminCapReceiverPubPath).borrow()
                ?? panic("could not borrow AdminCapReceiver capability")
			let idRef = getAccount(to).capabilities.get<&Admin>(FiatToken.AdminUUIDPubPath).borrow()
                ?? panic("could not borrow Admin ResourceId capability")

			receiver.setAdminCap(cap: newCap)

			emit AdminChanged(address: to, resourceId: idRef.UUID())
		}
	}
	
    /// Multisig signers call public functions in this resource
    /// to submit signatures to execute AdminExecutor functionality
	access(all)	resource Admin: OnChainMultiSig.PublicSigner, ResourceId, AdminCapReceiver, MultiSigManagerDefaultImpl { 

		access(OnChainMultiSig.Owner) let multiSigManager: @OnChainMultiSig.Manager
		
		access(self) var adminExecutorCapability: Capability<&AdminExecutor>?
		
		access(all) fun setAdminCap(cap: Capability<&AdminExecutor>) { 
			pre { 
				self.adminExecutorCapability == nil:
					"Capability has already been set"
				cap.borrow() != nil:
					"Invalid capability"
			}
			self.adminExecutorCapability = cap
		}
		
		// ------- OnChainMultiSig.PublicSigner interfaces -------
		
		access(all) fun executeTx(txIndex: UInt64): @AnyResource? { 
			let p <- self.multiSigManager.readyForExecution(txIndex: txIndex) ?? panic("no ready transaction payload at given txIndex")
			switch p.method { 
				case "configureKey":
					let pubKey = p.getArg(i: 0)! as? String ?? panic("cannot downcast public key")
					let weight = p.getArg(i: 1)! as? UFix64 ?? panic("cannot downcast weight")
					let sa = p.getArg(i: 2)! as? UInt8 ?? panic("cannot downcast sig algo")
					self.multiSigManager.configureKeys(pks: [pubKey], kws: [weight], sa: [sa])
				case "removeKey":
					let pubKey = p.getArg(i: 0)! as? String ?? panic("cannot downcast public key")
					self.multiSigManager.removeKeys(pks: [pubKey])
				case "removePayload":
					let txIndex = p.getArg(i: 0)! as? UInt64 ?? panic("cannot downcast txIndex")
					let payloadToRemove <- self.multiSigManager.removePayload(txIndex: txIndex)
					destroy payloadToRemove
				case "upgradeContract":
					let name = p.getArg(i: 0)! as? String ?? panic("cannot downcast contract name")
					let code = p.getArg(i: 1)! as? String ?? panic("cannot downcast contract code")
					let version = p.getArg(i: 2)! as? String ?? panic("cannot downcast contract version")
					let executor = (self.adminExecutorCapability!).borrow() ?? panic("cannot borrow AdminExecutor capability")
					executor.upgradeContract(name: name, code: code.decodeHex(), version: version)
				case "changeAdmin":
					let to = p.getArg(i: 0)! as? Address ?? panic("cannot downcast receiver address")
					let executor = (self.adminExecutorCapability!).borrow() ?? panic("cannot borrow AdminExecutor capability")
					executor.changeAdmin(to: to)
				default:
					panic("Unknown transaction method")
			}
			destroy p
			return nil
		}
		
		init(pk: [String], pka: [OnChainMultiSig.PubKeyAttr]) { 
			self.multiSigManager <- OnChainMultiSig.createMultiSigManager(publicKeys: pk, pubKeyAttrs: pka)
			self.adminExecutorCapability = nil
		}
	}
	
	access(all)	resource OwnerExecutor { 
		
		access(all) fun reassignOwner(to: Address) { 
            FiatToken.unlinkPrivateCapabilities(FiatToken.OwnerExecutorStoragePath)

			let newCap = FiatToken.account.capabilities.storage.issue<&OwnerExecutor>(FiatToken.OwnerExecutorStoragePath)

			let receiver = getAccount(to).capabilities.get<&Owner>(FiatToken.OwnerCapReceiverPubPath).borrow()
                ?? panic("could not borrow the OwnerCapReceiver capability")
			let idRef = getAccount(to).capabilities.get<&Owner>(FiatToken.OwnerUUIDPubPath).borrow()
                ?? panic("could not borrow the Owner ResourceId capability")
			receiver.setOwnerCap(cap: newCap)

			emit OwnerChanged(address: to, resourceId: idRef.UUID())
		}
		
		access(all) fun reassignMasterMinter(to: Address) { 
            FiatToken.unlinkPrivateCapabilities(FiatToken.MasterMinterExecutorStoragePath)

			let newCap = FiatToken.account.capabilities.storage.issue<&MasterMinterExecutor>(FiatToken.MasterMinterExecutorStoragePath)

			let receiver = getAccount(to).capabilities.get<&MasterMinter>(FiatToken.MasterMinterCapReceiverPubPath).borrow()
                ?? panic("could not borrow the MasterMinterCapReceiver capability")
			let idRef = getAccount(to).capabilities.get<&MasterMinter>(FiatToken.MasterMinterUUIDPubPath).borrow()
                ?? panic("could not borrow the MasterMinter ResourceId capability")
			receiver.setMasterMinterCap(cap: newCap)

			emit MasterMinterChanged(address: to, resourceId: idRef.UUID())
		}
		
		access(all) fun reassignBlocklister(to: Address) { 
            FiatToken.unlinkPrivateCapabilities(FiatToken.BlocklistExecutorStoragePath)

			let newCap = FiatToken.account.capabilities.storage.issue<&BlocklistExecutor>(FiatToken.BlocklistExecutorStoragePath)

			let receiver = getAccount(to).capabilities.get<&Blocklister>(FiatToken.BlocklisterCapReceiverPubPath).borrow()
                ?? panic("could not borrow the BlocklisterCapReceiver capability ")
			let idRef = getAccount(to).capabilities.get<&Blocklister>(FiatToken.BlocklisterUUIDPubPath).borrow()
                ?? panic("could not borrow the Blocklister ResourceId capability")
			receiver.setBlocklistCap(cap: newCap)

			emit BlocklisterChanged(address: to, resourceId: idRef.UUID())
		}
		
		access(all) fun reassignPauser(to: Address) { 
            FiatToken.unlinkPrivateCapabilities(FiatToken.PauseExecutorStoragePath)

			let newCap = FiatToken.account.capabilities.storage.issue<&FiatToken.PauseExecutor>(FiatToken.PauseExecutorStoragePath)
			let receiver = getAccount(to).capabilities.get<&Pauser>(FiatToken.PauserCapReceiverPubPath).borrow()
                ?? panic("could not borrow the PauseCapReceiver capability")
			let idRef = getAccount(to).capabilities.get<&Pauser>(FiatToken.PauserUUIDPubPath).borrow()
                ?? panic("could not borrow the Pauser ResourceId capability")
			receiver.setPauseCap(cap: newCap)

			emit PauserChanged(address: to, resourceId: idRef.UUID())
		}
	}
	
	access(all)	resource Owner: OnChainMultiSig.PublicSigner, ResourceId, OwnerCapReceiver, MultiSigManagerDefaultImpl { 
		access(OnChainMultiSig.Owner) let multiSigManager: @OnChainMultiSig.Manager
		
		access(self) var ownerExecutorCapability: Capability<&OwnerExecutor>?
		
		access(all) fun setOwnerCap(cap: Capability<&OwnerExecutor>) { 
			pre{ 
				self.ownerExecutorCapability == nil:
					"Capability has already been set"
				cap.borrow() != nil:
					"Invalid capability"
			}
			self.ownerExecutorCapability = cap
		}
		
		// ------- OnChainMultiSig.PublicSigner interfaces -------
		
		access(all) fun executeTx(txIndex: UInt64): @AnyResource? { 
			let p <- self.multiSigManager.readyForExecution(txIndex: txIndex) ?? panic("no ready transaction payload at given txIndex")
			switch p.method{ 
				case "configureKey":
					let pubKey = p.getArg(i: 0)! as? String ?? panic("cannot downcast public key")
					let weight = p.getArg(i: 1)! as? UFix64 ?? panic("cannot downcast weight")
					let sa = p.getArg(i: 2)! as? UInt8 ?? panic("cannot downcast sig algo")
					self.multiSigManager.configureKeys(pks: [pubKey], kws: [weight], sa: [sa])
				case "removeKey":
					let pubKey = p.getArg(i: 0)! as? String ?? panic("cannot downcast public key")
					self.multiSigManager.removeKeys(pks: [pubKey])
				case "reassignOwner":
					let to = p.getArg(i: 0)! as? Address ?? panic("cannot downcast receiver address")
					let executor = (self.ownerExecutorCapability!).borrow() ?? panic("cannot borrow OwnerExecutor capability")
					executor.reassignOwner(to: to)
				case "reassignMasterMinter":
					let to = p.getArg(i: 0)! as? Address ?? panic("cannot downcast receiver address")
					let executor = (self.ownerExecutorCapability!).borrow() ?? panic("cannot borrow OwnerExecutor capability")
					executor.reassignMasterMinter(to: to)
				case "reassignBlocklister":
					let to = p.getArg(i: 0)! as? Address ?? panic("cannot downcast receiver address")
					let executor = (self.ownerExecutorCapability!).borrow() ?? panic("cannot borrow OwnerExecutor capability")
					executor.reassignBlocklister(to: to)
				case "reassignPauser":
					let to = p.getArg(i: 0)! as? Address ?? panic("cannot downcast receiver address")
					let executor = (self.ownerExecutorCapability!).borrow() ?? panic("cannot borrow OwnerExecutor capability")
					executor.reassignPauser(to: to)
				default:
					panic("Unknown transaction method")
			}
			destroy p
			return nil
		}
		
		init(pk: [String], pka: [OnChainMultiSig.PubKeyAttr]) { 
			self.multiSigManager <- OnChainMultiSig.createMultiSigManager(publicKeys: pk, pubKeyAttrs: pka)
			self.ownerExecutorCapability = nil
		}
	}
	
	access(all)	resource MasterMinterExecutor { 
		access(all) fun configureMinterController(minter: UInt64, minterController: UInt64) { 
			// Overwrite the minter if the MinterController is already configured (a MinterController can only control 1 minter)
			FiatToken.managedMinters.insert(key: minterController, minter)
			emit ControllerConfigured(controller: minterController, minter: minter)
		}
		
		access(all) fun removeMinterController(minterController: UInt64) { 
			pre{ 
				FiatToken.managedMinters.containsKey(minterController):
					"cannot remove unknown MinterController"
			}
			FiatToken.managedMinters.remove(key: minterController)
			emit ControllerRemoved(controller: minterController)
		}
	}
	
	access(all)	resource MasterMinter: ResourceId, OnChainMultiSig.PublicSigner, MasterMinterCapReceiver, MultiSigManagerDefaultImpl { 
		access(OnChainMultiSig.Owner) let multiSigManager: @OnChainMultiSig.Manager
		
		access(self) var masterMinterExecutorCapability: Capability<&MasterMinterExecutor>?
		
		access(all) fun setMasterMinterCap(cap: Capability<&MasterMinterExecutor>) { 
			pre{ 
				self.masterMinterExecutorCapability == nil:
					"Capability has already been set"
				cap.borrow() != nil:
					"Invalid capability"
			}
			self.masterMinterExecutorCapability = cap
		}
		
		// ------- OnChainMultiSig.PublicSigner interfaces -------
		
		access(all) fun executeTx(txIndex: UInt64): @AnyResource? { 
			let p <- self.multiSigManager.readyForExecution(txIndex: txIndex) ?? panic("no ready transaction payload at given txIndex")
			switch p.method{ 
				case "configureKey":
					let pubKey = p.getArg(i: 0)! as? String ?? panic("cannot downcast public key")
					let weight = p.getArg(i: 1)! as? UFix64 ?? panic("cannot downcast weight")
					let sa = p.getArg(i: 2)! as? UInt8 ?? panic("cannot downcast sig algo")
					self.multiSigManager.configureKeys(pks: [pubKey], kws: [weight], sa: [sa])
				case "removeKey":
					let pubKey = p.getArg(i: 0)! as? String ?? panic("cannot downcast public key")
					self.multiSigManager.removeKeys(pks: [pubKey])
				case "configureMinterController":
					let m = p.getArg(i: 0)! as? UInt64 ?? panic("cannot downcast minter id")
					let mc = p.getArg(i: 1)! as? UInt64 ?? panic("cannot downcast MinterController id")
					let executor = (self.masterMinterExecutorCapability!).borrow() ?? panic("cannot borrow MasterMinterExecutor capability")
					executor.configureMinterController(minter: m, minterController: mc)
				case "removeMinterController":
					let mc = p.getArg(i: 0)! as? UInt64 ?? panic("cannot downcast MinterController id")
					let executor = (self.masterMinterExecutorCapability!).borrow() ?? panic("cannot borrow MasterMinterExecutor capability")
					executor.removeMinterController(minterController: mc)
				default:
					panic("Unknown transaction method")
			}
			destroy p
			return nil
		}
		
		init(pk: [String], pka: [OnChainMultiSig.PubKeyAttr]) { 
			self.multiSigManager <- OnChainMultiSig.createMultiSigManager(publicKeys: pk, pubKeyAttrs: pka)
			self.masterMinterExecutorCapability = nil
		}
	}
	
	access(all) resource MinterController: ResourceId, OnChainMultiSig.PublicSigner, MultiSigManagerDefaultImpl { 
		access(OnChainMultiSig.Owner) let multiSigManager: @OnChainMultiSig.Manager
		
		access(OnChainMultiSig.Owner) fun configureMinterAllowance(allowance: UFix64) { 
			let managedMinter = FiatToken.managedMinters[self.uuid] ?? panic("MinterController does not manage any minters")
			FiatToken.minterAllowances[managedMinter] = allowance
			emit MinterConfigured(controller: self.uuid, minter: managedMinter, allowance: allowance)
		}
		
		access(OnChainMultiSig.Owner) fun increaseMinterAllowance(increment: UFix64) { 
			let managedMinter = FiatToken.managedMinters[self.uuid] ?? panic("MinterController does not manage any minters")
			let allowance = FiatToken.minterAllowances[managedMinter] ?? 0.0
			let newAllowance = allowance.saturatingAdd(increment)
			self.configureMinterAllowance(allowance: newAllowance)
		}
		
		access(OnChainMultiSig.Owner) fun decreaseMinterAllowance(decrement: UFix64) { 
			let managedMinter = FiatToken.managedMinters[self.uuid] ?? panic("MinterController does not manage any minters")
			let allowance = FiatToken.minterAllowances[managedMinter] ?? panic("Cannot decrease nil MinterAllowance")
			let newAllowance = (allowance!).saturatingSubtract(decrement)
			self.configureMinterAllowance(allowance: newAllowance)
		}
		
		access(OnChainMultiSig.Owner) fun removeMinter() { 
			let managedMinter = FiatToken.managedMinters[self.uuid] ?? panic("MinterController does not manage any minters")
			assert(FiatToken.minterAllowances.containsKey(managedMinter), message: "cannot remove unknown Minter")
			FiatToken.minterAllowances.remove(key: managedMinter)
			emit MinterRemoved(controller: self.uuid, minter: managedMinter)
		}
		
		// ------- OnChainMultiSig.PublicSigner interfaces -------
		
		access(all) fun executeTx(txIndex: UInt64): @AnyResource? { 
			let p <- self.multiSigManager.readyForExecution(txIndex: txIndex) ?? panic("no ready transaction payload at given txIndex")
			switch p.method{ 
				case "configureKey":
					let pubKey = p.getArg(i: 0)! as? String ?? panic("cannot downcast public key")
					let weight = p.getArg(i: 1)! as? UFix64 ?? panic("cannot downcast weight")
					let sa = p.getArg(i: 2)! as? UInt8 ?? panic("cannot downcast sig algo")
					self.multiSigManager.configureKeys(pks: [pubKey], kws: [weight], sa: [sa])
				case "removeKey":
					let pubKey = p.getArg(i: 0)! as? String ?? panic("cannot downcast public key")
					self.multiSigManager.removeKeys(pks: [pubKey])
				case "configureMinterAllowance":
					let allowance = p.getArg(i: 0)! as? UFix64 ?? panic("cannot downcast allowance amount")
					self.configureMinterAllowance(allowance: allowance)
				case "increaseMinterAllowance":
					let increment = p.getArg(i: 0)! as? UFix64 ?? panic("cannot downcast increment amount")
					self.increaseMinterAllowance(increment: increment)
				case "decreaseMinterAllowance":
					let decrement = p.getArg(i: 0)! as? UFix64 ?? panic("cannot downcast decrement amount")
					self.decreaseMinterAllowance(decrement: decrement)
				case "removeMinter":
					self.removeMinter()
				default:
					panic("Unknown transaction method")
			}
			destroy p
			return nil
		}
		
		init(pk: [String], pka: [OnChainMultiSig.PubKeyAttr]) { 
			self.multiSigManager <- OnChainMultiSig.createMultiSigManager(publicKeys: pk, pubKeyAttrs: pka)
		}
	}
	
	access(all)	resource Minter: ResourceId { 
		access(OnChainMultiSig.Owner) fun mint(amount: UFix64): @{FungibleToken.Vault} { 
			pre{ 
				!FiatToken.paused:
					"FiatToken contract paused"
				FiatToken.blocklist[self.uuid] == nil:
					"Minter Blocklisted"
				FiatToken.minterAllowances.containsKey(self.uuid):
					"minter does not have allowance set"
			}
			let mintAllowance = FiatToken.minterAllowances[self.uuid]!
			assert(mintAllowance >= amount, message: "insufficient mint allowance")
			FiatToken.minterAllowances.insert(key: self.uuid, mintAllowance - amount)
			let newTotalSupply = FiatToken.totalSupply + amount
			FiatToken.totalSupply = newTotalSupply
			emit Mint(minter: self.uuid, amount: amount)
			return <-create Vault(balance: amount)
		}
	}
	
	access(all)	resource BlocklistExecutor { 
		access(all) fun blocklist(resourceId: UInt64) { 
			let block = getCurrentBlock()
			FiatToken.blocklist.insert(key: resourceId, block.height)
			emit Blocklisted(resourceId: resourceId)
		}
		
		access(all) fun unblocklist(resourceId: UInt64) { 
			FiatToken.blocklist.remove(key: resourceId)
			emit Unblocklisted(resourceId: resourceId)
		}
	}
	
	access(all) resource Blocklister: ResourceId, BlocklisterCapReceiver, OnChainMultiSig.PublicSigner, MultiSigManagerDefaultImpl { 
		access(self) var blocklistCap: Capability<&BlocklistExecutor>?
		
		access(OnChainMultiSig.Owner) let multiSigManager: @OnChainMultiSig.Manager
		
		access(OnChainMultiSig.Owner) fun blocklist(resourceId: UInt64) { 
			post{ 
				FiatToken.blocklist.containsKey(resourceId):
					"Resource not blocklisted"
			}
			((self.blocklistCap!).borrow()!).blocklist(resourceId: resourceId)
		}
		
		access(OnChainMultiSig.Owner) fun unblocklist(resourceId: UInt64) { 
			post{ 
				!FiatToken.blocklist.containsKey(resourceId):
					"Resource still on blocklist"
			}
			((self.blocklistCap!).borrow()!).unblocklist(resourceId: resourceId)
		}
		
		access(all) fun setBlocklistCap(cap: Capability<&BlocklistExecutor>) { 
			pre{ 
				self.blocklistCap == nil:
					"Capability has already been set"
				cap.borrow() != nil:
					"Invalid BlocklistCap capability"
			}
			self.blocklistCap = cap
		}
		
		// ------- OnChainMultiSig.PublicSigner interfaces -------
		
		access(all) fun executeTx(txIndex: UInt64): @AnyResource? { 
			let p <- self.multiSigManager.readyForExecution(txIndex: txIndex) ?? panic("no ready transaction payload at given txIndex")
			switch p.method{ 
				case "configureKey":
					let pubKey = p.getArg(i: 0)! as? String ?? panic("cannot downcast public key")
					let weight = p.getArg(i: 1)! as? UFix64 ?? panic("cannot downcast weight")
					let sa = p.getArg(i: 2)! as? UInt8 ?? panic("cannot downcast sig algo")
					self.multiSigManager.configureKeys(pks: [pubKey], kws: [weight], sa: [sa])
				case "removeKey":
					let pubKey = p.getArg(i: 0)! as? String ?? panic("cannot downcast public key")
					self.multiSigManager.removeKeys(pks: [pubKey])
				case "blocklist":
					let resourceId = p.getArg(i: 0)! as? UInt64 ?? panic("cannot downcast resourceId")
					self.blocklist(resourceId: resourceId)
				case "unblocklist":
					let resourceId = p.getArg(i: 0)! as? UInt64 ?? panic("cannot downcast resourceId")
					self.unblocklist(resourceId: resourceId)
				default:
					panic("Unknown transaction method")
			}
			destroy p
			return nil
		}
		
		init(pk: [String], pka: [OnChainMultiSig.PubKeyAttr]) { 
			self.blocklistCap = nil
			self.multiSigManager <- OnChainMultiSig.createMultiSigManager(publicKeys: pk, pubKeyAttrs: pka)
		}
	}
	
	access(all)	resource PauseExecutor { 
		access(all) fun pause() { 
			FiatToken.paused = true
			emit Paused()
		}
		
		access(all) fun unpause() { 
			FiatToken.paused = false
			emit Unpaused()
		}
	}
	
	access(all)	resource Pauser: ResourceId, PauseCapReceiver, OnChainMultiSig.PublicSigner, MultiSigManagerDefaultImpl { 
		access(self) var pauseCap: Capability<&PauseExecutor>?
		
		access(OnChainMultiSig.Owner) let multiSigManager: @OnChainMultiSig.Manager
		
		access(all) fun setPauseCap(cap: Capability<&PauseExecutor>) { 
			pre{ 
				self.pauseCap == nil:
					"Capability has already been set"
				cap.borrow() != nil:
					"Invalid PauseCap capability"
			}
			self.pauseCap = cap
		}
		
		access(OnChainMultiSig.Owner) fun pause() { 
			let cap = (self.pauseCap!).borrow()!
			cap.pause()
		}
		
		access(OnChainMultiSig.Owner) fun unpause() { 
			let cap = (self.pauseCap!).borrow()!
			cap.unpause()
		}
		
		// ------- OnChainMultiSig.PublicSigner interfaces -------
		
		access(all) fun executeTx(txIndex: UInt64): @AnyResource? { 
			let p <- self.multiSigManager.readyForExecution(txIndex: txIndex) ?? panic("no ready transaction payload at given txIndex")
			switch p.method{ 
				case "configureKey":
					let pubKey = p.getArg(i: 0)! as? String ?? panic("cannot downcast public key")
					let weight = p.getArg(i: 1)! as? UFix64 ?? panic("cannot downcast weight")
					let sa = p.getArg(i: 2)! as? UInt8 ?? panic("cannot downcast sig algo")
					self.multiSigManager.configureKeys(pks: [pubKey], kws: [weight], sa: [sa])
				case "removeKey":
					let pubKey = p.getArg(i: 0)! as? String ?? panic("cannot downcast public key")
					self.multiSigManager.removeKeys(pks: [pubKey])
				case "pause":
					self.pause()
				case "unpause":
					self.unpause()
				default:
					panic("Unknown transaction method")
			}
			destroy p
			return nil
		}
		
		init(pk: [String], pka: [OnChainMultiSig.PubKeyAttr]) { 
			self.pauseCap = nil
			self.multiSigManager <- OnChainMultiSig.createMultiSigManager(publicKeys: pk, pubKeyAttrs: pka)
		}
	}
	
	// ------- FiatToken functions -------
	access(all)	fun createEmptyVault(vaultType: Type): @{FungibleToken.Vault} { 
		let r <- create Vault(balance: 0.0)
		emit NewVault(resourceId: r.uuid)
		return <-r
	}
	
	access(all) fun createNewAdmin(publicKeys: [String], pubKeyAttrs: [OnChainMultiSig.PubKeyAttr]): @Admin { 
		let admin <- create Admin(pk: publicKeys, pka: pubKeyAttrs)
		emit AdminCreated(resourceId: admin.uuid)
		return <-admin
	}
	
	access(all) fun createNewOwner(publicKeys: [String], pubKeyAttrs: [OnChainMultiSig.PubKeyAttr]): @Owner { 
		let owner <- create Owner(pk: publicKeys, pka: pubKeyAttrs)
		emit OwnerCreated(resourceId: owner.uuid)
		return <-owner
	}
	
	access(all) fun createNewPauser(publicKeys: [String], pubKeyAttrs: [OnChainMultiSig.PubKeyAttr]): @Pauser { 
		let pauser <- create Pauser(pk: publicKeys, pka: pubKeyAttrs)
		emit PauserCreated(resourceId: pauser.uuid)
		return <-pauser
	}
	
	access(all) fun createNewMasterMinter(publicKeys: [String], pubKeyAttrs: [OnChainMultiSig.PubKeyAttr]): @MasterMinter { 
		let masterMinter <- create MasterMinter(pk: publicKeys, pka: pubKeyAttrs)
		emit MasterMinterCreated(resourceId: masterMinter.uuid)
		return <-masterMinter
	}
	
	access(all) fun createNewMinterController(publicKeys: [String], pubKeyAttrs: [OnChainMultiSig.PubKeyAttr]): @MinterController { 
		let minterController <- create MinterController(pk: publicKeys, pka: pubKeyAttrs)
		emit MinterControllerCreated(resourceId: minterController.uuid)
		return <-minterController
	}
	
	access(all) fun createNewMinter(): @Minter { 
		let minter <- create Minter()
		emit MinterCreated(resourceId: minter.uuid)
		return <-minter
	}
	
	access(all) fun createNewBlocklister(publicKeys: [String], pubKeyAttrs: [OnChainMultiSig.PubKeyAttr]): @Blocklister { 
		let blocklister <- create Blocklister(pk: publicKeys, pka: pubKeyAttrs)
		emit BlocklisterCreated(resourceId: blocklister.uuid)
		return <-blocklister
	}
	
	access(all) fun getBlocklist(resourceId: UInt64): UInt64? { 
		return FiatToken.blocklist[resourceId]
	}
	
	access(all) fun getManagedMinter(resourceId: UInt64): UInt64? { 
		return FiatToken.managedMinters[resourceId]
	}
	
	access(all) fun getMinterAllowance(resourceId: UInt64): UFix64? { 
		return FiatToken.minterAllowances[resourceId]
	}
	
	access(self) fun upgradeContract(name: String, code: [UInt8], version: String) { 
		self.account.contracts.update(name: name, code: code)
		self.version = version
	}

    // -------- ViewResolver Functions for MetadataViews --------

    access(all) view fun getContractViews(resourceType: Type?): [Type] {
        return [
            Type<FungibleTokenMetadataViews.FTView>(),
            Type<FungibleTokenMetadataViews.FTDisplay>(),
            Type<FungibleTokenMetadataViews.FTVaultData>(),
            Type<FungibleTokenMetadataViews.TotalSupply>()
        ]
    }

    access(all) fun resolveContractView(resourceType: Type?, viewType: Type): AnyStruct? {
        switch viewType {
            case Type<FungibleTokenMetadataViews.FTView>():
                return FungibleTokenMetadataViews.FTView(
                    ftDisplay: self.resolveContractView(resourceType: nil, viewType: Type<FungibleTokenMetadataViews.FTDisplay>()) as! FungibleTokenMetadataViews.FTDisplay?,
                    ftVaultData: self.resolveContractView(resourceType: nil, viewType: Type<FungibleTokenMetadataViews.FTVaultData>()) as! FungibleTokenMetadataViews.FTVaultData?
                )
            case Type<FungibleTokenMetadataViews.FTDisplay>():
                let media = MetadataViews.Media(
                        file: MetadataViews.HTTPFile(
                        url: ""
                    ),
                    mediaType: ""
                )
                let medias = MetadataViews.Medias([media])
                return FungibleTokenMetadataViews.FTDisplay(
                    name: "Circle USDC",
                    symbol: "USDC",
                    description: "This is the Flow Cadence version of USDC",
                    externalURL: MetadataViews.ExternalURL("https://www.circle.com/en/usdc"),
                    logos: medias,
                    socials: {
                        "twitter": MetadataViews.ExternalURL("https://twitter.com/circle")
                    }
                )
            case Type<FungibleTokenMetadataViews.FTVaultData>():
                return FungibleTokenMetadataViews.FTVaultData(
                    storagePath: self.VaultStoragePath,
                    receiverPath: self.VaultReceiverPubPath,
                    metadataPath: self.VaultBalancePubPath,
                    receiverLinkedType: Type<&FiatToken.Vault>(),
                    metadataLinkedType: Type<&FiatToken.Vault>(),
                    createEmptyVaultFunction: (fun(): @{FungibleToken.Vault} {
                        return <-FiatToken.createEmptyVault(vaultType: Type<@FiatToken.Vault>())
                    })
                )
            case Type<FungibleTokenMetadataViews.TotalSupply>():
                return FungibleTokenMetadataViews.TotalSupply(
                    totalSupply: FiatToken.totalSupply
                )
        }
        return nil
    }
	
	// ------- FiatToken Initializer -------
    init(
        // VaultStoragePath: StoragePath,
        // VaultBalancePubPath: PublicPath,
        // VaultUUIDPubPath: PublicPath,
        // VaultReceiverPubPath: PublicPath,
        // BlocklistExecutorStoragePath: StoragePath,
        // BlocklisterStoragePath: StoragePath,
        // BlocklisterCapReceiverPubPath: PublicPath,
        // BlocklisterUUIDPubPath: PublicPath,
        // BlocklisterPubSigner: PublicPath,
        // PauseExecutorStoragePath: StoragePath,
        // PauserStoragePath: StoragePath,
        // PauserCapReceiverPubPath: PublicPath,
        // PauserUUIDPubPath: PublicPath,
        // PauserPubSigner: PublicPath,
        // AdminExecutorStoragePath: StoragePath,
        // AdminStoragePath: StoragePath,
        // AdminCapReceiverPubPath: PublicPath,
        // AdminUUIDPubPath: PublicPath,
        // AdminPubSigner: PublicPath,
        // OwnerExecutorStoragePath: StoragePath,
        // OwnerStoragePath: StoragePath,
        // OwnerCapReceiverPubPath: PublicPath,
        // OwnerUUIDPubPath: PublicPath,
        // OwnerPubSigner: PublicPath,
        // MasterMinterExecutorStoragePath: StoragePath,
        // MasterMinterStoragePath: StoragePath,
        // MasterMinterCapReceiverPubPath: PublicPath,
        // MasterMinterPubSigner: PublicPath,
        // MasterMinterUUIDPubPath: PublicPath,
        // MinterControllerStoragePath: StoragePath,
        // MinterControllerUUIDPubPath: PublicPath,
        // MinterControllerPubSigner: PublicPath,
        // MinterStoragePath: StoragePath,
        // MinterUUIDPubPath: PublicPath,
        // tokenName: String,
        // version: String,
        // initTotalSupply: UFix64,
        // initPaused: Bool,
        adminPubKeys: [String],
        adminPubKeysWeights: [UFix64],
        adminPubKeysAlgos: [UInt8],
        ownerPubKeys: [String],
        ownerPubKeysWeights: [UFix64],
        ownerPubKeysAlgos: [UInt8],
        masterMinterPubKeys: [String],
        masterMinterPubKeysWeights: [UFix64],
        masterMinterPubKeysAlgos: [UInt8],
        blocklisterPubKeys: [String],
        blocklisterPubKeysWeights: [UFix64],
        blocklisterPubKeysAlgos: [UInt8],
        pauserPubKeys: [String],
        pauserPubKeysWeights: [UFix64],
        pauserPubKeysAlgos: [UInt8],
    ) {	

		// Validate the keys
		// assert(adminPubKeys.length == adminPubKeysWeights.length, message: "Admin pub keys length and weights mismatched")
		// assert(ownerPubKeys.length == ownerPubKeysWeights.length, message: "Owner pub keys length and weights mismatched")
		// assert(masterMinterPubKeys.length == masterMinterPubKeysWeights.length, message: "MasterMinter pub keys length and weights mismatched")
		// assert(blocklisterPubKeys.length == blocklisterPubKeysWeights.length, message: "Blocklister pub keys length and weights mismatched")
		// assert(pauserPubKeys.length == pauserPubKeysWeights.length, message: "Pauser pub keys length and weights mismatched")
		
        let VaultStoragePath = StoragePath(identifier: "USDCVault")!
        let VaultBalancePubPath = PublicPath(identifier: "USDCVaultBalance")!
        let VaultReceiverPubPath = PublicPath(identifier: "USDCVaultReceiver")!
        let VaultUUIDPubPath = PublicPath(identifier: "USDCVaultUUID")!

        let BlocklistExecutorStoragePath = StoragePath(identifier: "USDCBlocklistExe")!
        let BlocklisterStoragePath = StoragePath(identifier: "USDCBlocklister")!
        let BlocklisterCapReceiverPubPath = PublicPath(identifier: "USDCBlocklisterCapReceiver")!
        let BlocklisterUUIDPubPath = PublicPath(identifier: "USDCBlocklisterUUID")!
        let BlocklisterPubSigner = PublicPath(identifier: "USDCBlocklisterPublicSigner")!

        let PauseExecutorStoragePath = StoragePath(identifier: "USDCPauseExe")!
        let PauserStoragePath = StoragePath(identifier: "USDCPauser")!
        let PauserCapReceiverPubPath = PublicPath(identifier: "USDCPauserCapReceiver")!
        let PauserUUIDPubPath = PublicPath(identifier: "USDCPauserUUID")!
        let PauserPubSigner = PublicPath(identifier: "USDCPauserPublicSigner")!

        let AdminExecutorStoragePath = StoragePath(identifier: "USDCAdminExe")!
        let AdminStoragePath = StoragePath(identifier: "USDCAdmin")!
        let AdminCapReceiverPubPath = PublicPath(identifier: "USDCAdminCapReceiver")!
        let AdminUUIDPubPath = PublicPath(identifier: "USDCAdminUUID")!
        let AdminPubSigner = PublicPath(identifier: "USDCAdminPublicSigner")!

        let OwnerExecutorStoragePath = StoragePath(identifier: "USDCOwnerExe")!
        let OwnerStoragePath = StoragePath(identifier: "USDCOwner")!
        let OwnerCapReceiverPubPath = PublicPath(identifier: "USDCOwnerCapReceiver")!
        let OwnerUUIDPubPath = PublicPath(identifier: "USDCOwnerUUID")!
        let OwnerPubSigner = PublicPath(identifier: "USDCOwnerPubSigner")!

        let MasterMinterExecutorStoragePath = StoragePath(identifier: "USDCMasterMinterExe")!
        let MasterMinterStoragePath = StoragePath(identifier: "USDCMasterMinter")!
        let MasterMinterCapReceiverPubPath = PublicPath(identifier: "USDCMasterMinterCapReceiver")!
        let MasterMinterPubSigner = PublicPath(identifier: "USDCMasterMinterPublicSigner")!
        let MasterMinterUUIDPubPath = PublicPath(identifier: "USDCMasterMinterUUID")!

        let MinterControllerStoragePath = StoragePath(identifier: "USDCMinterController")!
        let MinterControllerUUIDPubPath = PublicPath(identifier: "USDCMinterControllerUUID")!
        let MinterControllerPubSigner = PublicPath(identifier: "USDCMinterControllerPublicSigner")!

        let MinterStoragePath = StoragePath(identifier: "USDCMinter")!
        let MinterUUIDPubPath = PublicPath(identifier: "USDCMinterUUID")!

        let tokenName = "USDC"
        let version = "2.0.0"
        let initTotalSupply = 1000.0
        let initPaused = false

		// Set the State
		self.name = tokenName
		self.version = version
		self.paused = initPaused
		self.totalSupply = initTotalSupply
		self.blocklist ={} 
		self.minterAllowances ={} 
		self.managedMinters ={} 
		self.VaultStoragePath = VaultStoragePath
		self.VaultBalancePubPath = VaultBalancePubPath
		self.VaultUUIDPubPath = VaultUUIDPubPath
		self.VaultReceiverPubPath = VaultReceiverPubPath
		self.BlocklistExecutorStoragePath = BlocklistExecutorStoragePath
		self.BlocklisterStoragePath = BlocklisterStoragePath
		self.BlocklisterCapReceiverPubPath = BlocklisterCapReceiverPubPath
		self.BlocklisterUUIDPubPath = BlocklisterUUIDPubPath
		self.BlocklisterPubSigner = BlocklisterPubSigner
		self.PauseExecutorStoragePath = PauseExecutorStoragePath
		self.PauserStoragePath = PauserStoragePath
		self.PauserCapReceiverPubPath = PauserCapReceiverPubPath
		self.PauserUUIDPubPath = PauserUUIDPubPath
		self.PauserPubSigner = PauserPubSigner
		self.AdminExecutorStoragePath = AdminExecutorStoragePath
		self.AdminStoragePath = AdminStoragePath
		self.AdminCapReceiverPubPath = AdminCapReceiverPubPath
		self.AdminUUIDPubPath = AdminUUIDPubPath
		self.AdminPubSigner = AdminPubSigner
		self.OwnerExecutorStoragePath = OwnerExecutorStoragePath
		self.OwnerStoragePath = OwnerStoragePath
		self.OwnerCapReceiverPubPath = OwnerCapReceiverPubPath
		self.OwnerUUIDPubPath = OwnerUUIDPubPath
		self.OwnerPubSigner = OwnerPubSigner
		self.MasterMinterExecutorStoragePath = MasterMinterExecutorStoragePath
		self.MasterMinterStoragePath = MasterMinterStoragePath
		self.MasterMinterCapReceiverPubPath = MasterMinterCapReceiverPubPath
		self.MasterMinterPubSigner = MasterMinterPubSigner
		self.MasterMinterUUIDPubPath = MasterMinterUUIDPubPath
		self.MinterControllerStoragePath = MinterControllerStoragePath
		self.MinterControllerUUIDPubPath = MinterControllerUUIDPubPath
		self.MinterControllerPubSigner = MinterControllerPubSigner
		self.MinterStoragePath = MinterStoragePath
		self.MinterUUIDPubPath = MinterUUIDPubPath
		
		// Create admin accounts
		let adminAccount = self.account // Account(payer: self.account)
		let ownerAccount = self.account // Account(payer: self.account)
		let masterMinterAccount = self.account // Account(payer: self.account)
		let blocklisterAccount = self.account // Account(payer: self.account)
		let pauserAccount = self.account // Account(payer: self.account)
		
		// Create the Executors
		self.account.storage.save(<-create AdminExecutor(), to: self.AdminExecutorStoragePath)
		self.account.storage.save(<-create OwnerExecutor(), to: self.OwnerExecutorStoragePath)
		self.account.storage.save(<-create MasterMinterExecutor(), to: self.MasterMinterExecutorStoragePath)
		self.account.storage.save(<-create BlocklistExecutor(), to: self.BlocklistExecutorStoragePath)
		self.account.storage.save(<-create PauseExecutor(), to: self.PauseExecutorStoragePath)
		
		// Setup the Admin
		var pubKeyAttrs: [OnChainMultiSig.PubKeyAttr] = []
		// var i = 0
		// while i < adminPubKeys.length{ 
		// 	let pka = OnChainMultiSig.PubKeyAttr(sa: adminPubKeysAlgos[i], w: adminPubKeysWeights[i])
		// 	pubKeyAttrs.append(pka)
		// 	let key = PublicKey(publicKey: adminPubKeys[i].decodeHex(), signatureAlgorithm: SignatureAlgorithm(rawValue: adminPubKeysAlgos[i]) ?? panic("Invalid signature algo"))
		// 	adminAccount.keys.add(publicKey: key, hashAlgorithm: HashAlgorithm.SHA3_256, weight: adminPubKeysWeights[i])
		// 	i = i + 1
		// }

		adminAccount.storage.save(<-self.createNewAdmin(publicKeys: adminPubKeys, pubKeyAttrs: pubKeyAttrs), to: self.AdminStoragePath)
		let adminCap = adminAccount.capabilities.storage.issue<&Admin>(self.AdminStoragePath)
        adminAccount.capabilities.publish(adminCap, at: self.AdminPubSigner)
        adminAccount.capabilities.publish(adminCap, at: self.AdminUUIDPubPath)
        adminAccount.capabilities.publish(adminCap, at: self.AdminCapReceiverPubPath)
		
		// Setup the Owner
		pubKeyAttrs = []
		// i = 0
		// while i < ownerPubKeys.length{ 
		// 	let pka = OnChainMultiSig.PubKeyAttr(sa: ownerPubKeysAlgos[i], w: ownerPubKeysWeights[i])
		// 	pubKeyAttrs.append(pka)
		// 	let key = PublicKey(publicKey: ownerPubKeys[i].decodeHex(), signatureAlgorithm: SignatureAlgorithm(rawValue: ownerPubKeysAlgos[i]) ?? panic("Invalid signature algo"))
		// 	ownerAccount.keys.add(publicKey: key, hashAlgorithm: HashAlgorithm.SHA3_256, weight: ownerPubKeysWeights[i])
		// 	i = i + 1
		// }
		ownerAccount.storage.save(<-self.createNewOwner(publicKeys: ownerPubKeys, pubKeyAttrs: pubKeyAttrs), to: self.OwnerStoragePath)
		let ownerCap = ownerAccount.capabilities.storage.issue<&Owner>(self.OwnerStoragePath)
        ownerAccount.capabilities.publish(ownerCap, at: self.OwnerPubSigner)
		ownerAccount.capabilities.publish(ownerCap, at: self.OwnerUUIDPubPath)
		ownerAccount.capabilities.publish(ownerCap, at: self.OwnerCapReceiverPubPath)
		
		// Setup the MasterMinter
		pubKeyAttrs = []
		// i = 0
		// while i < masterMinterPubKeys.length{ 
		// 	let pka = OnChainMultiSig.PubKeyAttr(sa: masterMinterPubKeysAlgos[i], w: masterMinterPubKeysWeights[i])
		// 	pubKeyAttrs.append(pka)
		// 	let key = PublicKey(publicKey: masterMinterPubKeys[i].decodeHex(), signatureAlgorithm: SignatureAlgorithm(rawValue: masterMinterPubKeysAlgos[i]) ?? panic("Invalid signature algo"))
		// 	masterMinterAccount.keys.add(publicKey: key, hashAlgorithm: HashAlgorithm.SHA3_256, weight: masterMinterPubKeysWeights[i])
		// 	i = i + 1
		// }
        masterMinterAccount.storage.save(<-self.createNewMasterMinter(publicKeys: masterMinterPubKeys, pubKeyAttrs: pubKeyAttrs), to: self.MasterMinterStoragePath)
		let masterMinterCap = masterMinterAccount.capabilities.storage.issue<&MasterMinter>(self.MasterMinterStoragePath)
        masterMinterAccount.capabilities.publish(masterMinterCap, at: self.MasterMinterPubSigner)
		masterMinterAccount.capabilities.publish(masterMinterCap, at: self.MasterMinterUUIDPubPath)
		masterMinterAccount.capabilities.publish(masterMinterCap, at: self.MasterMinterCapReceiverPubPath)
		
		// Setup the Blocklister 
		pubKeyAttrs = []
		// i = 0
		// while i < blocklisterPubKeys.length{ 
		// 	let pka = OnChainMultiSig.PubKeyAttr(sa: blocklisterPubKeysAlgos[i], w: blocklisterPubKeysWeights[i])
		// 	pubKeyAttrs.append(pka)
		// 	let key = PublicKey(publicKey: blocklisterPubKeys[i].decodeHex(), signatureAlgorithm: SignatureAlgorithm(rawValue: blocklisterPubKeysAlgos[i]) ?? panic("Invalid signature algo"))
		// 	blocklisterAccount.keys.add(publicKey: key, hashAlgorithm: HashAlgorithm.SHA3_256, weight: blocklisterPubKeysWeights[i])
		// 	i = i + 1
		// }
        blocklisterAccount.storage.save(<-self.createNewBlocklister(publicKeys: blocklisterPubKeys, pubKeyAttrs: pubKeyAttrs), to: self.BlocklisterStoragePath)
		let blocklisterCap = blocklisterAccount.capabilities.storage.issue<&Blocklister>(self.BlocklisterStoragePath)
        blocklisterAccount.capabilities.publish(blocklisterCap, at: self.BlocklisterPubSigner)
		blocklisterAccount.capabilities.publish(blocklisterCap, at: self.BlocklisterUUIDPubPath)
		blocklisterAccount.capabilities.publish(blocklisterCap, at: self.BlocklisterCapReceiverPubPath)
		
		// Setup the Pauser
		pubKeyAttrs = []
		// i = 0
		// while i < pauserPubKeys.length{ 
		// 	let pka = OnChainMultiSig.PubKeyAttr(sa: pauserPubKeysAlgos[i], w: pauserPubKeysWeights[i])
		// 	pubKeyAttrs.append(pka)
		// 	let key = PublicKey(publicKey: pauserPubKeys[i].decodeHex(), signatureAlgorithm: SignatureAlgorithm(rawValue: pauserPubKeysAlgos[i]) ?? panic("Invalid signature algo"))
		// 	pauserAccount.keys.add(publicKey: key, hashAlgorithm: HashAlgorithm.SHA3_256, weight: pauserPubKeysWeights[i])
		// 	i = i + 1
		// }
        pauserAccount.storage.save(<-self.createNewPauser(publicKeys: pauserPubKeys, pubKeyAttrs: pubKeyAttrs), to: self.PauserStoragePath)
		let pauserCap = pauserAccount.capabilities.storage.issue<&Pauser>(self.BlocklisterStoragePath)
        pauserAccount.capabilities.publish(pauserCap, at: self.PauserPubSigner)
		pauserAccount.capabilities.publish(pauserCap, at: self.PauserUUIDPubPath)
		pauserAccount.capabilities.publish(pauserCap, at: self.PauserCapReceiverPubPath)
		
		// Assign the admin capabilities
		let adminExecutorRef = self.account.storage.borrow<&FiatToken.AdminExecutor>(from: self.AdminExecutorStoragePath) ?? panic("cannot borrow AdminExecutor from storage")
		let ownerExecutorRef = self.account.storage.borrow<&FiatToken.OwnerExecutor>(from: self.OwnerExecutorStoragePath) ?? panic("cannot borrow OwnerExecutor from storage")
		adminExecutorRef.changeAdmin(to: adminAccount.address)
		ownerExecutorRef.reassignOwner(to: ownerAccount.address)
		ownerExecutorRef.reassignMasterMinter(to: masterMinterAccount.address)
		ownerExecutorRef.reassignBlocklister(to: blocklisterAccount.address)
		ownerExecutorRef.reassignPauser(to: pauserAccount.address)
		
		// Create a Vault with the initial totalSupply
		let vault <- create Vault(balance: self.totalSupply)
		self.account.storage.save(<-vault, to: self.VaultStoragePath)
		
		// Create public capabilities to the vault
        let tokenCap = self.account.capabilities.storage.issue<&FiatToken.Vault>(self.VaultStoragePath)
        self.account.capabilities.publish(tokenCap, at: self.VaultReceiverPubPath)
        self.account.capabilities.publish(tokenCap, at: self.VaultBalancePubPath)
		self.account.capabilities.publish(tokenCap, at: self.VaultUUIDPubPath)
	}
}