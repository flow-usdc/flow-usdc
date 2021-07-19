<!-- markdownlint-disable -->
# transactions
# blocklist
## blocklist_rsc.cdc
 This tx is used for blocklister to blocklist a resource.
 This will fail: 
 - if the blocklister does not have delegated capability given by the BlocklistExecutor
 - if the resource has already been blocklisted


```cadence
transaction(resourceId: UInt64) {
    prepare (blocklister: AuthAccount) {
        let blocklister = blocklister.borrow<&FiatToken.Blocklister>(from: FiatToken.BlocklisterStoragePath) ?? panic("cannot borrow own private path")
        blocklister.blocklist(resourceId: resourceId);
    } 

    post {
        FiatToken.blocklist[resourceId]! != nil: "Resource not blocklisted";
        FiatToken.blocklist[resourceId] == getCurrentBlock().height : "Blocklisted on incorrect height";

    }
}
```


## create_new_blocklister.cdc

```cadence
transaction(blocklisterAddr: Address) {
    prepare (blocklister: AuthAccount) {
        
        // Check and return if they already have a pauser resource
        if blocklister.borrow<&FiatToken.Blocklister>(from: FiatToken.BlocklisterStoragePath) != nil {
            return
        }
        
        blocklister.save(<- FiatToken.createNewBlocklister(), to: FiatToken.BlocklisterStoragePath);
        
        blocklister.link<&FiatToken.Blocklister{FiatToken.BlocklistCapReceiver}>(FiatToken.BlocklisterCapReceiverPubPath, target: FiatToken.BlocklisterStoragePath)
        ??  panic("Could not link BlocklistCapReceiver");
    } 

    post {
        getAccount(blocklisterAddr).getCapability<&FiatToken.Blocklister{FiatToken.BlocklistCapReceiver}>(FiatToken.BlocklisterCapReceiverPubPath).check() :
        "BlocklistCapReceiver link not set"
    }
}
```


## unblocklist_rsc.cdc
 This tx is used for blocklister to blocklist a resource.
 This will fail: 
 - if the blocklister does not have delegated capability given by the BlocklistExecutor
 - if the resource is not currently blocklisted


```cadence
transaction(resourceId: UInt64) {
    prepare (blocklister: AuthAccount) {
        let blocklister = blocklister.borrow<&FiatToken.Blocklister>(from: FiatToken.BlocklisterStoragePath) ?? panic("cannot borrow own private path")
        blocklister.unblocklist(resourceId: resourceId);
    } 

    post {
        FiatToken.blocklist[resourceId] == nil : "Resource still on blocklist"
    }
}
```


## create_vault.cdc
 This transaction is a template for a transaction
 to add a Vault resource to their account
 so that they can use FiatToken 

```cadence
transaction {

    prepare(signer: AuthAccount) {

        // Return early if the account already stores a FiatToken Vault
        if signer.borrow<&FiatToken.Vault>(from: FiatToken.VaultStoragePath) != nil {
            return
        }

        // Create a new ExampleToken Vault and put it in storage
        signer.save(
            <-FiatToken.createEmptyVault(),
            to: FiatToken.VaultStoragePath
        )

        // Create a public capability to the Vault that only exposes
        // the deposit function through the Receiver interface
        signer.link<&FiatToken.Vault{FungibleToken.Receiver}>(
            FiatToken.VaultReceiverPubPath,
            target: FiatToken.VaultStoragePath
        )

        // Create a public capability to the Vault that only exposes
        // the withdrawAllowace function through the WithdrawAllowance interface
        // Anyone can all this method but only those with allowance set will succeed
        signer.link<&FiatToken.Vault{FiatTokenInterface.Allowance}>(
            FiatToken.VaultAllowancePubPath,
            target: FiatToken.VaultStoragePath
        )

        // Create a public capability to the Vault that only exposes
        // the UUID() function through the VaultUUID interface
        signer.link<&FiatToken.Vault{FiatTokenInterface.VaultUUID}>(
            FiatToken.VaultUUIDPubPath,
            target: FiatToken.VaultStoragePath
        )

        // Create a public capability to the Vault that only exposes
        // the balance field through the Balance interface
        signer.link<&FiatToken.Vault{FungibleToken.Balance}>(
            FiatToken.VaultBalancePubPath,
            target: FiatToken.VaultStoragePath
        )
    }
}
```


## deploy_contract_with_auth.cdc
 This transactions deploys the FiatToken contract

 Owner of the contract has exclusive functions
 We only provide the AuthAccount holder the owner resource

```cadence
transaction(
    contractName: String, 
    code: String,
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
    prepare(owner: AuthAccount) {
        let existingContract = owner.contracts.get(name: contractName)

        if (existingContract == nil) {
            owner.contracts.add(
                name: contractName, 
                code: code.decodeHex(), 
                owner,
                VaultStoragePath: VaultStoragePath,
                VaultBalancePubPath: VaultBalancePubPath,
                VaultUUIDPubPath: VaultUUIDPubPath,
                VaultAllowancePubPath: VaultAllowancePubPath,
                VaultReceiverPubPath: VaultReceiverPubPath,
                BlocklistExecutorStoragePath: BlocklistExecutorStoragePath,
                BlocklistExecutorPrivPath: BlocklistExecutorPrivPath,
                BlocklisterStoragePath: BlocklisterStoragePath,
                BlocklisterCapReceiverPubPath: BlocklisterCapReceiverPubPath,
                PauseExecutorStoragePath: PauseExecutorStoragePath, 
                PauseExecutorPrivPath: PauseExecutorPrivPath,
                PauserStoragePath: PauserStoragePath,
                PauserCapReceiverPubPath: PauserCapReceiverPubPath,
                OwnerStoragePath: OwnerStoragePath,
                OwnerPrivPath: OwnerPrivPath,
                MasterMinterStoragePath: MasterMinterStoragePath,
                MasterMinterPrivPath: MasterMinterPrivPath,
                MinterControllerStoragePath:  MinterControllerStoragePath,
                MinterControllerUUIDPubPath: MinterControllerUUIDPubPath,
                MinterStoragePath: MinterStoragePath,
                MinterUUIDPubPath: MinterUUIDPubPath,
                tokenName: tokenName,
                initTotalSupply: initTotalSupply,
                initPaused: initPaused, 
            )
        } else {
            owner.contracts.update__experimental(name: contractName, code: code.decodeHex())
        }
    }
}
```


# mint
## burn.cdc
 Minter can burn tokens from a given vault
 This script withdraws tokens from minter own vault to burn the tokens


```cadence
transaction(amount: UFix64) {

    prepare(minter: AuthAccount) {

        // Get a reference to the signer's stored vault
        let vaultRef = minter.borrow<&FiatToken.Vault>(from: FiatToken.VaultStoragePath)
            ?? panic("Could not borrow reference to the owner's Vault!")

        // Withdraw tokens from the minter's stored vault
        let burnVault <- vaultRef.withdraw(amount: amount)

        let m = minter.borrow<&FiatToken.Minter>(from: FiatToken.MinterStoragePath) 
            ?? panic ("no minter resource avaialble");

        m.burn(vault: <-burnVault);
    }
}
```


## configure_minter_allowance.cdc
 MinterController uses this to configure minter allowance 


```cadence
transaction (amount: UFix64) {
    prepare(minterController: AuthAccount) {
        let mc = minterController.borrow<&FiatToken.MinterController>(from: FiatToken.MinterControllerStoragePath) 
            ?? panic ("no minter controller resource avaialble");

        mc.configureMinterAllowance(allowance: amount);
    }
}
```


## create_new_minter.cdc

```cadence
transaction(minterAddr: Address) {
    prepare (minter: AuthAccount) {
        
        // Check and return if they already have a minter resource
        if minter.borrow<&FiatToken.Minter>(from: FiatToken.MinterStoragePath) != nil {
            return
        }
        
        minter.save(<- FiatToken.createNewMinter(), to: FiatToken.MinterStoragePath);
        
        minter.link<&FiatToken.Minter{FiatToken.ResourceId}>(FiatToken.MinterUUIDPubPath, target: FiatToken.MinterStoragePath)
        ??  panic("Could not link minter uuid");
    } 

    post {
        getAccount(minterAddr).getCapability<&{FiatToken.ResourceId}>(FiatToken.MinterUUIDPubPath).check() :
        "MinterUUID link not set"
    }
}
```


## create_new_minter_controller.cdc

```cadence
transaction(minterControllerAddr: Address) {
    prepare (minterController: AuthAccount) {
        
        // Check and return if they already have a minter controller resource
        if minterController.borrow<&FiatToken.MinterController>(from: FiatToken.MinterControllerStoragePath) != nil {
            return
        }
        
        minterController.save(<- FiatToken.createNewMinterController(), to: FiatToken.MinterControllerStoragePath);
        
        minterController.link<&FiatToken.MinterController{FiatToken.ResourceId}>(FiatToken.MinterControllerUUIDPubPath, target: FiatToken.MinterControllerStoragePath)
        ??  panic("Could not link minter controller uuid");
    } 

    post {
        getAccount(minterControllerAddr).getCapability<&{FiatToken.ResourceId}>(FiatToken.MinterControllerUUIDPubPath).check() :
        "MinterControllerUUID link not set"
    }
}
```


## decrease_minter_allowance.cdc
 MinterController uses this to decrease minter allowance 


```cadence
transaction (amount: UFix64) {
    prepare(minterController: AuthAccount) {
        let mc = minterController.borrow<&FiatToken.MinterController>(from: FiatToken.MinterControllerStoragePath) 
            ?? panic ("no minter controller resource avaialble");

        mc.decreaseMinterAllowance(decrement: amount);
    }
}
```


## increase_minter_allowance.cdc
 MinterController uses this to increase minter allowance 


```cadence
transaction (amount: UFix64) {
    prepare(minterController: AuthAccount) {
        let mc = minterController.borrow<&FiatToken.MinterController>(from: FiatToken.MinterControllerStoragePath) 
            ?? panic ("no minter controller resource avaialble");

        mc.increaseMinterAllowance(increment: amount);
    }
}
```


## mint.cdc
 This script mints token on FiatToken contract and deposits the minted amount to the receiver's Vault 
 It will fail if minter does not have allowance, is blocklisted or contract is paused


```cadence
transaction (amount: UFix64, receiver: Address) {
    let mintedVault: @FungibleToken.Vault;

    prepare(minter: AuthAccount) {
        let m = minter.borrow<&FiatToken.Minter>(from: FiatToken.MinterStoragePath) 
            ?? panic ("no minter resource avaialble");
        self.mintedVault <- m.mint(amount: amount)
    }

    execute {
        let recvAcct = getAccount(receiver);
        let receiverRef = recvAcct.getCapability(FiatToken.VaultReceiverPubPath)
            .borrow<&{FungibleToken.Receiver}>()
            ?? panic("Could not borrow receiver reference to the recipient's Vault")

        receiverRef.deposit(from: <-self.mintedVault)
    }
}
```


## remove_minter.cdc
 MinterController uses this to remove minter 


```cadence
transaction () {
    prepare(minterController: AuthAccount) {
        let mc = minterController.borrow<&FiatToken.MinterController>(from: FiatToken.MinterControllerStoragePath) 
            ?? panic ("no minter controller resource avaialble");
        mc.removeMinter();
    }
}
```


# owner
## configure_minter_controller.cdc
 Masterminter uses this to configure which minter the minter controller manages


```cadence
transaction (minter: UInt64, minterController: UInt64) {
    prepare(masterMinter: AuthAccount) {
        let mm = masterMinter.borrow<&FiatToken.MasterMinter{FiatTokenInterface.MasterMinter}>(from: FiatToken.MasterMinterStoragePath) 
            ?? panic ("no masterminter resource avaialble");

        mm.configureMinterController(minter: minter, minterController: minterController);
    }
    post {
        FiatToken.managedMinters[minterController] == minter : "minterController not configured"
    }
}
```


## remove_minter_controller.cdc
 Masterminter uses this to remove minter controller


```cadence
transaction (minterController: UInt64 ) {
    prepare(masterMinter: AuthAccount) {
        let mm = masterMinter.borrow<&FiatToken.MasterMinter{FiatTokenInterface.MasterMinter}>(from: FiatToken.MasterMinterStoragePath) 
            ?? panic ("no masterminter resource avaialble");

        mm.removeMinterController(minterController: minterController);
    }
    post {
        !FiatToken.managedMinters.containsKey(minterController) : "minterController not removed"
    }
}
```


## set_blocklist_cap.cdc
 The account with the PauseExecutor Resource can use this script to 
 provide capability for a pauser to pause the contract


```cadence
transaction (blocklister: Address) {
    prepare(blocklistExe: AuthAccount) {
        let cap = blocklistExe.getCapability<&FiatToken.BlocklistExecutor>(FiatToken.BlocklistExecutorPrivPath);
        if !cap.check() {
            panic ("cannot borrow such capability") 
        } else {
            let setCapRef = getAccount(blocklister).getCapability<&FiatToken.Blocklister{FiatToken.BlocklistCapReceiver}>(FiatToken.BlocklisterCapReceiverPubPath).borrow() ?? panic("Cannot get blocklistCapReceiver");
            setCapRef.setBlocklistCap(blocklistCap: cap);
        }
    }

}
```


## set_pause_cap.cdc
 The account with the PauseExecutor Resource can use this script to 
 provide capability for a pauser to pause the contract


```cadence
transaction (pauser: Address) {
    prepare(pauseExe: AuthAccount) {
        let cap = pauseExe.getCapability<&FiatToken.PauseExecutor>(FiatToken.PauseExecutorPrivPath);
        if !cap.check() {
            panic ("cannot borrow such capability") 
        } else {
            let setCapRef = getAccount(pauser).getCapability<&FiatToken.Pauser{FiatToken.PauseCapReceiver}>(FiatToken.PauserCapReceiverPubPath).borrow() ?? panic("Cannot get pauseCapReceiver");
            setCapRef.setPauseCap(pauseCap: cap);
        }
    }

}
```


# pause
## create_new_pauser.cdc

```cadence
transaction(pauserAddr: Address) {
    prepare (pauser: AuthAccount) {
        
        // Check and return if they already have a pauser resource
        if pauser.borrow<&FiatToken.Pauser>(from: FiatToken.PauserStoragePath) != nil {
            return
        }
        
        pauser.save(<- FiatToken.createNewPauser(), to: FiatToken.PauserStoragePath);
        
        pauser.link<&FiatToken.Pauser{FiatToken.PauseCapReceiver}>(FiatToken.PauserCapReceiverPubPath, target: FiatToken.PauserStoragePath)
        ??  panic("Could not link PauserCapReceiver");
    } 

    post {
        getAccount(pauserAddr).getCapability<&FiatToken.Pauser{FiatToken.PauseCapReceiver}>(FiatToken.PauserCapReceiverPubPath).check() :
        "PauserCapReceiver link not set"
    }
}
```


## pause_contract.cdc

```cadence
transaction {
    prepare (pauser: AuthAccount) {

        let pauser = pauser.borrow<&FiatToken.Pauser>(from: FiatToken.PauserStoragePath) ?? panic("cannot borrow own private path")
        pauser.pause();
    } 

    post {
        FiatToken.paused: "pause contract error"
    }
}
```


## unpause_contract.cdc

```cadence
transaction {
    prepare (pauser: AuthAccount) {

        let pauser = pauser.borrow<&FiatToken.Pauser>(from: FiatToken.PauserStoragePath) ?? panic("cannot borrow own private path")
        pauser.unpause();
    } 

    post {
        !FiatToken.paused: "unpause contract error"
    }
}
```


## transfer_FiatToken.cdc
 This transaction is a template for a transaction that
 could be used by anyone to send tokens to another account
 that has been set up to receive tokens.

 The withdraw amount and the account from getAccount
 would be the parameters to the transaction


```cadence
transaction(amount: UFix64, to: Address) {

    // The Vault resource that holds the tokens that are being transferred
    let sentVault: @FungibleToken.Vault

    prepare(signer: AuthAccount) {

        // Get a reference to the signer's stored vault
        let vaultRef = signer.borrow<&FiatToken.Vault>(from: FiatToken.VaultStoragePath)
            ?? panic("Could not borrow reference to the owner's Vault!")

        // Withdraw tokens from the signer's stored vault
        self.sentVault <- vaultRef.withdraw(amount: amount)
    }

    execute {

        // Get the recipient's public account object
        let recipient = getAccount(to)

        // Get a reference to the recipient's Receiver
        let receiverRef = recipient.getCapability(FiatToken.VaultReceiverPubPath)
            .borrow<&{FungibleToken.Receiver}>()
            ?? panic("Could not borrow receiver reference to the recipient's Vault")

        // Deposit the withdrawn tokens in the recipient's receiver
        receiverRef.deposit(from: <-self.sentVault)
    }
}
```


## transfer_flow_tokens_emulator.cdc
 This transaction is a template for a transaction that
 could be used by anyone to send tokens to another account
 that has been set up to receive tokens.

 The withdraw amount and the account from getAccount
 would be the parameters to the transaction

 Here we use hard-coded testnet addresses for the emulator
 This is required because the newly created account requires
 balance for the deployment of the FiatToken contract.


```cadence
transaction(amount: UFix64, to: Address) {

    // The Vault resource that holds the tokens that are being transferred
    let sentVault: @FungibleToken.Vault

    prepare(signer: AuthAccount) {

        // Get a reference to the signer's stored vault
        let vaultRef = signer.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault)
			?? panic("Could not borrow reference to the owner's Vault!")

        // Withdraw tokens from the signer's stored vault
        self.sentVault <- vaultRef.withdraw(amount: amount)
    }

    execute {

        // Get a reference to the recipient's Receiver
        let receiverRef =  getAccount(to)
            .getCapability(/public/flowTokenReceiver)
            .borrow<&{FungibleToken.Receiver}>()
			?? panic("Could not borrow receiver reference to the recipient's Vault")

        // Deposit the withdrawn tokens in the recipient's receiver
        receiverRef.deposit(from: <-self.sentVault)
    }
}
```



## transfer_flow_tokens_testnet.cdc
 This transaction is a template for a transaction that
 could be used by anyone to send tokens to another account
 that has been set up to receive tokens.

 The withdraw amount and the account from getAccount
 would be the parameters to the transaction

 Here we use hard-coded testnet addresses because
 we only use this particular transaction on testnet

```cadence
transaction(amount: UFix64, to: Address) {

    // The Vault resource that holds the tokens that are being transferred
    let sentVault: @FungibleToken.Vault

    prepare(signer: AuthAccount) {

        // Get a reference to the signer's stored vault
        let vaultRef = signer.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault)
			?? panic("Could not borrow reference to the owner's Vault!")

        // Withdraw tokens from the signer's stored vault
        self.sentVault <- vaultRef.withdraw(amount: amount)
    }

    execute {

        // Get a reference to the recipient's Receiver
        let receiverRef =  getAccount(to)
            .getCapability(/public/flowTokenReceiver)
            .borrow<&{FungibleToken.Receiver}>()
			?? panic("Could not borrow receiver reference to the recipient's Vault")

        // Deposit the withdrawn tokens in the recipient's receiver
        receiverRef.deposit(from: <-self.sentVault)
    }
}
```



# vault
## approval.cdc

```cadence
transaction(toResourceId: UInt64, amount: UFix64) {

    prepare (fromAcct: AuthAccount) {
        // Get a reference to the signer's stored vault
        let vaultRef = fromAcct.borrow<&FiatToken.Vault>(from: FiatToken.VaultStoragePath)
            ?? panic("Could not borrow reference to the owner's Vault!")

        // Withdraw tokens from the signer's stored vault
        vaultRef.approval(resourceId: toResourceId, amount: amount)
    }
}
```


## decreaseAllowance.cdc

```cadence
transaction(toResourceId: UInt64, delta: UFix64) {

    prepare (fromAcct: AuthAccount) {
        // Get a reference to the signer's stored vault
        let vaultRef = fromAcct.borrow<&FiatToken.Vault>(from: FiatToken.VaultStoragePath)
            ?? panic("Could not borrow reference to the owner's Vault!")

        vaultRef.decreaseAllowance(resourceId: toResourceId, decrement: delta)
    }
}
```


## increaseAllowance.cdc

```cadence
transaction(toResourceId: UInt64, delta: UFix64) {

    prepare (fromAcct: AuthAccount) {
        // Get a reference to the signer's stored vault
        let vaultRef = fromAcct.borrow<&FiatToken.Vault>(from: FiatToken.VaultStoragePath)
            ?? panic("Could not borrow reference to the owner's Vault!")

        vaultRef.increaseAllowance(resourceId: toResourceId, increment: delta)
    }
}
```


## withdraw_allowance.cdc
 This transaction is a template for withdrawing allowance from a FiatToken vault


```cadence
transaction(fromAddr: Address, toAddr: Address, amount: UFix64) {
    
    prepare(signer: AuthAccount) {
       
    }

    execute {

        // Get the recipient's public account object
        let fromAcct = getAccount(fromAddr)

        // Get a allowance reference to the fromAcct's vault 
        let allowanceRef = fromAcct.getCapability(FiatToken.VaultAllowancePubPath)
            .borrow<&{FiatTokenInterface.Allowance}>()
            ?? panic("Could not borrow allowance reference")

        allowanceRef.withdrawAllowance(recvAddr: toAddr, amount: amount)
    }
}
```


