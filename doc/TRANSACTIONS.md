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
        FiatToken.getBlocklist(resourceId:resourceId)! != nil: "Resource not blocklisted";
        FiatToken.getBlocklist(resourceId:resourceId) == getCurrentBlock().height : "Blocklisted on incorrect height";

    }
}
```


## create_new_blocklister.cdc
 This creates a new blocklsiter resource.
 If no onchain-multisig is required, empty publicKeys and pubKeyWeights array can be used.
 If account already has a blocklisted, it will remove it and create a new one. 
 
 Blocklister does not have capability to blocklist until granted by owner of BlocklistExecutor.
 If a new one is created, the capability will be lost


```cadence
transaction(blocklisterAddr: Address, publicKeys: [String], pubKeyWeights: [UFix64]) {
    prepare (blocklister: AuthAccount) {
        
        // Check if they already have a blocklister resource, if so, destroy it
        if blocklister.borrow<&FiatToken.Blocklister>(from: FiatToken.BlocklisterStoragePath) != nil {
            blocklister.unlink(FiatToken.BlocklisterCapReceiverPubPath)
            blocklister.unlink(FiatToken.BlocklisterPubSigner)
            let b <- blocklister.load<@FiatToken.Blocklister>(from: FiatToken.BlocklisterStoragePath) 
            destroy b
        }
        
        var i = 0;
        let pka: [OnChainMultiSig.PubKeyAttr] = []
        while i < pubKeyWeights.length {
            let a = OnChainMultiSig.PubKeyAttr(sa: 1, w: pubKeyWeights[i])
            pka.append(a)
            i = i + 1;
        }

        blocklister.save(<- FiatToken.createNewBlocklister(publicKeys: publicKeys, pubKeyAttrs: pka), to: FiatToken.BlocklisterStoragePath);
        
        blocklister.link<&FiatToken.Blocklister{FiatToken.BlocklistCapReceiver}>(FiatToken.BlocklisterCapReceiverPubPath, target: FiatToken.BlocklisterStoragePath)
        ??  panic("Could not link BlocklistCapReceiver");

        blocklister.link<&FiatToken.Blocklister{OnChainMultiSig.PublicSigner}>(FiatToken.BlocklisterPubSigner, target: FiatToken.BlocklisterStoragePath)
        ??  panic("Could not link pauser pub signer");
    } 

    post {
        getAccount(blocklisterAddr).getCapability<&FiatToken.Blocklister{FiatToken.BlocklistCapReceiver}>(FiatToken.BlocklisterCapReceiverPubPath).check() :
        "BlocklistCapReceiver link not set"

        getAccount(blocklisterAddr).getCapability<&FiatToken.Blocklister{OnChainMultiSig.PublicSigner}>(FiatToken.BlocklisterPubSigner).check() :
        "BlocklistPubSigner link not set"
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
        FiatToken.getBlocklist(resourceId: resourceId) == nil : "Resource still on blocklist"
    }
}
```


# deploy
## deploy_contract_with_auth.cdc
 This transactions deploys the FiatToken contract

 Owner (AuthAccount) of this script is the owner of the contract

```cadence
transaction(
    contractName: String, 
    code: String,
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
                VaultPubSigner: VaultPubSigner,
                BlocklistExecutorStoragePath: BlocklistExecutorStoragePath,
                BlocklistExecutorPrivPath: BlocklistExecutorPrivPath,
                BlocklisterStoragePath: BlocklisterStoragePath,
                BlocklisterCapReceiverPubPath: BlocklisterCapReceiverPubPath,
                BlocklisterPubSigner: BlocklisterPubSigner,
                PauseExecutorStoragePath: PauseExecutorStoragePath, 
                PauseExecutorPrivPath: PauseExecutorPrivPath,
                PauserStoragePath: PauserStoragePath,
                PauserCapReceiverPubPath: PauserCapReceiverPubPath,
                PauserPubSigner: PauserPubSigner,
                OwnerStoragePath: OwnerStoragePath,
                OwnerPrivPath: OwnerPrivPath,
                MasterMinterStoragePath: MasterMinterStoragePath,
                MasterMinterPrivPath: MasterMinterPrivPath,
                MasterMinterPubSigner: MasterMinterPubSigner,
                MasterMinterUUIDPubPath: MasterMinterUUIDPubPath,
                MinterControllerStoragePath:  MinterControllerStoragePath,
                MinterControllerUUIDPubPath: MinterControllerUUIDPubPath,
                MinterControllerPubSigner: MinterControllerPubSigner,
                MinterStoragePath: MinterStoragePath,
                MinterUUIDPubPath: MinterUUIDPubPath,
                MinterPubSigner: MinterPubSigner,
                tokenName: tokenName,
                version: version,
                initTotalSupply: initTotalSupply,
                initPaused: initPaused, 
                ownerAccountPubKeys: ownerAccountPubKeys,
                ownerAccountKeyWeights: ownerAccountKeyWeights,
            )
        } else {
            owner.contracts.update__experimental(name: contractName, code: code.decodeHex())
        }
    }
}
```


# flowTokens
## create_account_testnet.cdc
 This creates an account and adds the public key with the weight

```cadence
transaction(publicKey: String, weight: UFix64) {
    prepare(signer: AuthAccount) {
        let key = PublicKey(
            publicKey: publicKey.decodeHex(),
            signatureAlgorithm: SignatureAlgorithm.ECDSA_P256
        )

        let account = AuthAccount(payer: signer)

        account.keys.add(
            publicKey: key,
            hashAlgorithm: HashAlgorithm.SHA3_256,
            weight: weight
        )
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
    log("transferring")
    log(to)

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



# mint
## burn.cdc
 This script withdraws tokens from minter own vault to burn the tokens
 Minter can burn tokens from a given vault


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


## create_new_minter.cdc
 This script creates a new Minter resource.
 If no onchain-multisig is required, empty publicKeys and pubKeyWeights array can be used.
 If account already has a Minter, it will remove it and create a new one. 
 
 Minter are granted allowance by the UUID.
 If a new one is created, the UUID will be different and will not have the same allowance. 


```cadence
transaction(minterAddr: Address, publicKeys: [String], pubKeyWeights: [UFix64]) {
    prepare (minter: AuthAccount) {
        
        // Check and return if they already have a minter resource
        if minter.borrow<&FiatToken.Minter>(from: FiatToken.MinterStoragePath) != nil {
            minter.unlink(FiatToken.MinterUUIDPubPath)
            minter.unlink(FiatToken.MinterPubSigner)
            let m <- minter.load<@FiatToken.Minter>(from: FiatToken.MinterStoragePath) 
            destroy m
        }
        
        var i = 0;
        let pka: [OnChainMultiSig.PubKeyAttr] = []
        while i < pubKeyWeights.length {
            let a = OnChainMultiSig.PubKeyAttr(sa: 1, w: pubKeyWeights[i])
            pka.append(a)
            i = i + 1;
        }
        
        minter.save(<- FiatToken.createNewMinter(publicKeys: publicKeys, pubKeyAttrs: pka), to: FiatToken.MinterStoragePath);
        
        minter.link<&FiatToken.Minter{FiatToken.ResourceId}>(FiatToken.MinterUUIDPubPath, target: FiatToken.MinterStoragePath)
        ??  panic("Could not link minter uuid");

        minter.link<&FiatToken.Minter{OnChainMultiSig.PublicSigner}>(FiatToken.MinterPubSigner, target: FiatToken.MinterStoragePath)
        ??  panic("Could not link minter pub signer");
    } 

    post {
        getAccount(minterAddr).getCapability<&{FiatToken.ResourceId}>(FiatToken.MinterUUIDPubPath).check() :
        "MinterUUID link not set"

        getAccount(minterAddr).getCapability<&{OnChainMultiSig.PublicSigner}>(FiatToken.MinterPubSigner).check() :
        "MinterPubSigner link not set"
    }
}
```


## mint.cdc
 This script mints token on FiatToken contract and deposits the minted amount to the receiver's Vault 
 It will fail if minter does not have enough allowance, is blocklisted or contract is paused


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


# minterControl
## configure_minter_allowance.cdc
 MinterController uses this to configure minter allowance 
 It succeeds of MinterController has assigned Minter from MasterMinter


```cadence
transaction (amount: UFix64) {
    prepare(minterController: AuthAccount) {
        let mc = minterController.borrow<&FiatToken.MinterController>(from: FiatToken.MinterControllerStoragePath) 
            ?? panic ("no minter controller resource avaialble");

        mc.configureMinterAllowance(allowance: amount);
    }
}
```


## create_new_minter_controller.cdc
 This script creates a new MinterController resource.
 If no onchain-multisig is required, empty publicKeys and pubKeyWeights array can be used.
 If account already has a MinterController, it will remove it and create a new one. 
 
 MinterController are assigned Minter by the UUID.
 If a new one is created, the UUID will be different and will not have the same Minter to control.


```cadence
transaction(minterControllerAddr: Address, publicKeys: [String], pubKeyWeights: [UFix64]) {
    prepare (minterController: AuthAccount) {
        
        // Check and return if they already have a minter controller resource
        if minterController.borrow<&FiatToken.MinterController>(from: FiatToken.MinterControllerStoragePath) != nil {
            minterController.unlink(FiatToken.MinterControllerUUIDPubPath)
            minterController.unlink(FiatToken.MinterControllerPubSigner)
            let m <- minterController.load<@FiatToken.MinterController>(from: FiatToken.MinterControllerStoragePath) 
            destroy m
        }

        var i = 0;
        let pka: [OnChainMultiSig.PubKeyAttr] = []
        while i < pubKeyWeights.length {
            let a = OnChainMultiSig.PubKeyAttr(sa: 1, w: pubKeyWeights[i])
            pka.append(a)
            i = i + 1;
        }
        
        minterController.save(<- FiatToken.createNewMinterController(publicKeys: publicKeys, pubKeyAttrs: pka), to: FiatToken.MinterControllerStoragePath);
        
        minterController.link<&FiatToken.MinterController{FiatToken.ResourceId}>(FiatToken.MinterControllerUUIDPubPath, target: FiatToken.MinterControllerStoragePath)
        ??  panic("Could not link minter controller uuid");

        minterController.link<&FiatToken.MinterController{OnChainMultiSig.PublicSigner}>(FiatToken.MinterControllerPubSigner, target: FiatToken.MinterControllerStoragePath)
        ??  panic("Could not link minter controller public signer");
    } 

    post {
        getAccount(minterControllerAddr).getCapability<&{FiatToken.ResourceId}>(FiatToken.MinterControllerUUIDPubPath).check() :
        "MinterControllerUUID link not set"

        getAccount(minterControllerAddr).getCapability<&{OnChainMultiSig.PublicSigner}>(FiatToken.MinterControllerPubSigner).check() :
        "MinterControllerPubSigner link not set"
    }
}
```


## decrease_minter_allowance.cdc
 MinterController uses this to decrease Minter allowance 
 It succeeds of MinterController has assigned Minter from MasterMinter
 and that the Minter previously has been configured and have allowance


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
 MinterController uses this to increase Minter allowance 
 It succeeds of MinterController has assigned Minter from MasterMinter


```cadence
transaction (amount: UFix64) {
    prepare(minterController: AuthAccount) {
        let mc = minterController.borrow<&FiatToken.MinterController>(from: FiatToken.MinterControllerStoragePath) 
            ?? panic ("no minter controller resource avaialble");

        mc.increaseMinterAllowance(increment: amount);
    }
}
```


## remove_minter.cdc
 MinterController uses this to remove Minter 
 A Minter must have been configured and under such control


```cadence
transaction () {
    prepare(minterController: AuthAccount) {
        let mc = minterController.borrow<&FiatToken.MinterController>(from: FiatToken.MinterControllerStoragePath) 
            ?? panic ("no minter controller resource avaialble");
        mc.removeMinter();
    }
}
```


# onChainMultiSig
## add_new_payload.cdc
 New payload (without a resource in the payload) to be added to multiSigManager for a resource 
 `resourcePubSignerPath` must have been linked by the resource owner
 `txIndex` must be the current resource index incremented by 1


```cadence
transaction (sig: String, txIndex: UInt64, method: String, args: [AnyStruct], publicKey: String, resourceAddr: Address, resourcePubSignerPath: PublicPath) {
    let rsc: @AnyResource?
    prepare(oneOfMultiSig: AuthAccount) {
        self.rsc <- nil
    }

    execute {
        let resourceAcct = getAccount(resourceAddr)

        let pubSigRef = resourceAcct.getCapability(resourcePubSignerPath)
            .borrow<&{OnChainMultiSig.PublicSigner}>()
            ?? panic("Could not borrow Public Signer reference")
        
        let p <- OnChainMultiSig.createPayload(txIndex: txIndex, method: method, args: args, rsc: <- self.rsc);
        return pubSigRef.addNewPayload(payload: <- p, publicKey: publicKey, sig: sig.decodeHex()) 
    }
}
```


## add_new_payload_with_vault.cdc
 New payload with a Vault resource to be added to multiSigManager for a resource
 
 `resourcePubSignerPath` must have been linked by the resource owner
 `txIndex` must be the current resource index incremented by 1
 The first argument in `args` must be the balance in the vault

```cadence
transaction (sig: String, txIndex: UInt64, method: String, args: [AnyStruct], publicKey: String, resourceAddr: Address, resourcePubSignerPath: PublicPath) {
    let rsc: @AnyResource?
    prepare(oneOfMultiSig: AuthAccount) {

        // Get a reference to the signer's stored vault
        let vaultRef = oneOfMultiSig.borrow<&FiatToken.Vault>(from: FiatToken.VaultStoragePath)
            ?? panic("Could not borrow reference to the owner's Vault!")

        // Withdraw tokens from the signer's stored vault
        let amount = args[0] as? UFix64 ?? panic("cannot downcast first arg as amount");
        self.rsc <- vaultRef.withdraw(amount: amount);
    }

    execute {
        let resourceAcct = getAccount(resourceAddr)

        let pubSigRef = resourceAcct.getCapability(resourcePubSignerPath)
            .borrow<&{OnChainMultiSig.PublicSigner}>()
            ?? panic("Could not borrow Public Signer reference")
        
        let p <- OnChainMultiSig.createPayload(txIndex: txIndex, method: method, args: args, rsc: <- self.rsc);
        return pubSigRef.addNewPayload(payload: <- p, publicKey: publicKey, sig: sig.decodeHex()) 
    }
}
```


## add_payload_signature.cdc
 New payload signature to be added to multiSigManager for a particular txIndex 


```cadence
transaction (sig: String, txIndex: UInt64, publicKey: String, resourceAddr: Address, resourcePubSignerPath: PublicPath) {
    prepare(oneOfMultiSig: AuthAccount) {
    }

    execute {
       let resourceAcct = getAccount(resourceAddr)

        let pubSigRef = resourceAcct.getCapability(resourcePubSignerPath)
            .borrow<&{OnChainMultiSig.PublicSigner}>()
            ?? panic("Could not borrow master minter pub sig reference")
            
        return pubSigRef.addPayloadSignature(txIndex: txIndex, publicKey: publicKey, sig: sig.decodeHex())
    }
}
```


## executeTx.cdc
 Executes an added Payload for onchain-multisig of a resource
 Note: Currently on supports the returning of a Vault.
 If the payload method returns a vault, it will be deposited to the caller's vault
 other types of returned resource is destroyed (both cases not used in FiatToken)
 


```cadence
transaction (txIndex: UInt64, resourceAddr: Address, resourcePubSignerPath: PublicPath) {
    let recv: &{FungibleToken.Receiver}
    prepare(oneOfMultiSig: AuthAccount) {
        // Get a reference to the signer's stored vault
        self.recv = oneOfMultiSig.getCapability(FiatToken.VaultReceiverPubPath)!
            .borrow<&{FungibleToken.Receiver}>()
            ?? panic("Unable to borrow receiver reference for recipient")
    }

    execute {
        let resourceAcct = getAccount(resourceAddr)

        let pubSigRef = resourceAcct.getCapability(resourcePubSignerPath)
            .borrow<&{OnChainMultiSig.PublicSigner}>()
            ?? panic("Could not borrow resource pub sig reference")

        let r <- pubSigRef.executeTx(txIndex: txIndex)
        if r != nil {
            // Withdraw tokens from the signer's stored vault
            let vault <- r! as! @FungibleToken.Vault
            self.recv.deposit(from: <- vault)
        } else {
            destroy(r)
        }
    }
}
```


# owner
## configure_minter_controller.cdc
 Masterminter uses this to configure which Minter the MinterController manages


```cadence
transaction (minter: UInt64, minterController: UInt64) {
    prepare(masterMinter: AuthAccount) {
        let mm = masterMinter.borrow<&FiatToken.MasterMinter{FiatTokenInterface.MasterMinter}>(from: FiatToken.MasterMinterStoragePath) 
            ?? panic ("no masterminter resource avaialble");

        mm.configureMinterController(minter: minter, minterController: minterController);
    }
    post {
        FiatToken.getManagedMinter(resourceId: minterController) == minter : "minterController not configured"
    }
}
```


## remove_minter_controller.cdc
 Masterminter uses this to remove MinterController
 Minter previously assigned allowances will still be valid.


```cadence
transaction (minterController: UInt64 ) {
    prepare(masterMinter: AuthAccount) {
        let mm = masterMinter.borrow<&FiatToken.MasterMinter{FiatTokenInterface.MasterMinter}>(from: FiatToken.MasterMinterStoragePath) 
            ?? panic ("no masterminter resource avaialble");

        mm.removeMinterController(minterController: minterController);
    }
    post {
        FiatToken.getManagedMinter(resourceId: minterController) == nil : "minterController not removed"
    }
}
```


## set_blocklist_cap.cdc
 The account with the BlocklistExecutor Resource can use this script to 
 provide capability for a blocklister to blocklist resources


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
 This creates a new pauser resource.
 If no onchain-multisig is required, empty publicKeys and pubKeyWeights array can be used.
 If account already has a Pauser, it will remove it and create a new one. 
 
 Pauser does not have capability to blocklist until granted by owner of PauseExecutor.
 If a new one is created, the capability will be lost


```cadence
transaction(pauserAddr: Address, publicKeys: [String], pubKeyWeights: [UFix64]) {
    prepare (pauser: AuthAccount) {
        
        // Check if account already have a pauser resource, if so destroy it
        if pauser.borrow<&FiatToken.Pauser>(from: FiatToken.PauserStoragePath) != nil {
            pauser.unlink(FiatToken.PauserCapReceiverPubPath)
            pauser.unlink(FiatToken.PauserPubSigner)
            let p <- pauser.load<@FiatToken.Pauser>(from: FiatToken.PauserStoragePath) 
            destroy p
        }
        
        var i = 0;
        let pka: [OnChainMultiSig.PubKeyAttr] = []
        while i < pubKeyWeights.length {
            let a = OnChainMultiSig.PubKeyAttr(sa: 1, w: pubKeyWeights[i])
            pka.append(a)
            i = i + 1;
        }

        pauser.save(<- FiatToken.createNewPauser(publicKeys: publicKeys, pubKeyAttrs: pka), to: FiatToken.PauserStoragePath);
        log("created new pauser")
        
        pauser.link<&FiatToken.Pauser{FiatToken.PauseCapReceiver}>(FiatToken.PauserCapReceiverPubPath, target: FiatToken.PauserStoragePath)
        ??  panic("Could not link PauserCapReceiver");

        pauser.link<&FiatToken.Pauser{OnChainMultiSig.PublicSigner}>(FiatToken.PauserPubSigner, target: FiatToken.PauserStoragePath)
        ??  panic("Could not link pauser pub signer");
    } 

    post {
        getAccount(pauserAddr).getCapability<&FiatToken.Pauser{FiatToken.PauseCapReceiver}>(FiatToken.PauserCapReceiverPubPath).check() :
        "PauserCapReceiver link not set"

        getAccount(pauserAddr).getCapability<&FiatToken.Pauser{OnChainMultiSig.PublicSigner}>(FiatToken.PauserPubSigner).check() :
        "PauserPubSigner link not set"
    }
}
```


## pause_contract.cdc
 This pauses the contract by a Pauser if capability was granted


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
 This unpauses the contract by a Pauser if capability was granted


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


# vault
## approval.cdc
 This script is used by Vault owner to approve an allowance for another Vault


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


## create_vault.cdc
 This script is used to add a Vault resource to their account so that they can use FiatToken 

 If the Vault already exist for the account, the script will return immediately without error
 
 If not onchain-multisig is required, pubkeys and key weights can be empty
 Vault resource must follow the FuntibleToken interface where initialiser only takes the balance
 As a result, the Vault owner is required to directly add public keys to the OnChainMultiSig.Manager
 via the `addKeys` method in the OnchainMultiSig.KeyManager interface.
 
 Therefore if multisig is required for the vault, the account itself should have the same key weight
 distribution as it does for the Vault.

```cadence
transaction(multiSigPubKeys: [String], multiSigKeyWeights: [UFix64]) {

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
        // the PublicSigner functions 
        // Anyone can all this method but only signatures from added public keys will succeed
        signer.link<&FiatToken.Vault{OnChainMultiSig.PublicSigner}>(
            FiatToken.VaultPubSigner,
            target: FiatToken.VaultStoragePath
        )

        // Create a public capability to the Vault that only exposes
        // the UUID() function through the VaultUUID interface
        signer.link<&FiatToken.Vault{FiatToken.ResourceId}>(
            FiatToken.VaultUUIDPubPath,
            target: FiatToken.VaultStoragePath
        )

        // Create a public capability to the Vault that only exposes
        // the balance field through the Balance interface
        signer.link<&FiatToken.Vault{FungibleToken.Balance}>(
            FiatToken.VaultBalancePubPath,
            target: FiatToken.VaultStoragePath
        )

        // The transaction that creates the vault can also add required multiSig public keys to the multiSigManager
        let s = signer.borrow<&FiatToken.Vault>(from: FiatToken.VaultStoragePath) ?? panic ("cannot borrow own resource")
        s.addKeys(multiSigPubKeys: multiSigPubKeys, multiSigKeyWeights: multiSigKeyWeights)
    }
}
```


## decreaseAllowance.cdc
 Vault owner decreases allowance for another Vault


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
 Vault owner increases allowance for another Vault


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


## move_and_deposit.cdc
 This transaction is used by accounts with a FiatToken Vault to move it and deposit
 its content into other vault


```cadence
transaction( to: Address) {

    // The Vault resource that holds the tokens that are being transferred
    let sentVault: @FiatToken.Vault

    prepare(signer: AuthAccount) {

        // Move self vault 
        self.sentVault <- signer.load<@FiatToken.Vault>(from: FiatToken.VaultStoragePath)
            ?? panic("Could not load the owner's Vault!")
    }

    execute {

        // Get the recipient's public account object
        let recipient = getAccount(to)

        // Get a reference to the recipient's Receiver
        let receiverRef = recipient.getCapability(FiatToken.VaultReceiverPubPath)
            .borrow<&{FungibleToken.Receiver}>()
            ?? panic("Could not borrow receiver reference to the recipient's Vault")

        // Deposit the tokens 
        receiverRef.deposit(from: <-self.sentVault)
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


## withdraw_allowance.cdc
 This transaction is a template for withdrawing allowance from a FiatToken vault
 It will be successful iff allowance is set for the toAddr


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


