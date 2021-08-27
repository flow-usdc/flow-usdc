<!-- markdownlint-disable -->
# scripts
## calc_signable_data.cdc
 This script returns cadence conversion from different types to bytes 
 Currently AnyStruct is input arg is not allowed, hence wrapping it in optional
```cadence
pub fun main(v: AnyStruct?): [UInt8] {
    let value = v!;
    switch value.getType(){
        case Type<String>():
            let temp = value as? String;
            return temp!.utf8;
        case Type<UInt64>():
            let temp = value as? UInt64;
            return temp!.toBigEndianBytes();
        case Type<UFix64>():
            let temp = value as? UFix64;
            return temp!.toBigEndianBytes();
        case Type<Address>():
            let temp = value as? Address;
            return temp!.toBytes();
        default:
            log("Type is not supported")
            return []
    }
}
```


# contract
## get_blocklist_status.cdc
 This gets the blocklist status of a resource
 If is it blocklisted, the block it happen will be returned
 If it is not blocklisted, nil will return


```cadence
pub fun main(uuid: UInt64): UInt64? {
    return FiatToken.getBlocklist(resourceId: uuid)
}
```


## get_managed_minter.cdc
 This gets the managed Minter of a MinterController
 If non is set by the MasterMinter, nil will return


```cadence
pub fun main(uuid: UInt64): UInt64? {
    return FiatToken.getManagedMinter(resourceId: uuid)
}
```


## get_minter_allowance.cdc
 This gets the Minter's allowance set by a MinterController
 If non is set, this will return error


```cadence
pub fun main(uuid: UInt64): UFix64 {
    return FiatToken.getMinterAllowance(resourceId: uuid)!
}
```


## get_name.cdc
 Gets the Token Name


```cadence
pub fun main(): String{
    return FiatToken.name
}
```


## get_paused.cdc
 Gets the pause state of the contract


```cadence
pub fun main(): Bool {
    return FiatToken.paused
}
```


## get_resource_uuid.cdc
 This script uses the resources PubSigner Public path to use the UUID function for uuid

 Alternatively, if the resource owner do not want to link PubSigner path, they can simply
 link the ResourceId interfaces and this script should then use the <Resource>UUIDPubPath, i.e. VaultUUIDPubPath


```cadence
pub fun main(resourceAddr: Address, resourceName: String): UInt64 {
    let resourceAcct = getAccount(resourceAddr)
    var resourcePubPath: PublicPath = FiatToken.VaultPubSigner

    switch resourceName {
        case "Vault":
            resourcePubPath = FiatToken.VaultPubSigner
        case "Minter":
            resourcePubPath = FiatToken.MinterPubSigner
        case "MinterController":
            resourcePubPath = FiatToken.MinterControllerPubSigner
        case "MasterMinter":
            resourcePubPath = FiatToken.MasterMinterPubSigner
        case "Pauser":
            resourcePubPath = FiatToken.PauserPubSigner
        case "Blocklister":
            resourcePubPath = FiatToken.BlocklisterPubSigner
        default:
            panic ("Resource not supported")
    }

    let ref = resourceAcct.getCapability(resourcePubPath)
        .borrow<&{OnChainMultiSig.PublicSigner}>()
        ?? panic("Could not borrow Get UUID reference to the Resource")

    return ref.UUID()
}
```


## get_total_supply.cdc
 This script reads the total supply field
 of the FiatToken smart contract


```cadence
pub fun main(): UFix64 {

    let supply = FiatToken.totalSupply

    log(supply)

    return supply
}
```


## get_version.cdc
 This gets the current version of the contract


```cadence
pub fun main(): String {
    return FiatToken.version
}
```


# onChainMultiSig
## get_key_weight.cdc
 This script gets the weight of a stored public key in a multiSigManager for a resource 


```cadence
pub fun main(resourceAddr: Address, key: String, resourcePubSignerPath: PublicPath): UFix64 {
    let resourceAcct = getAccount(resourceAddr)
    let ref = resourceAcct.getCapability(resourcePubSignerPath)
        .borrow<&{OnChainMultiSig.PublicSigner}>()
        ?? panic("Could not borrow Pub Signer reference to the Vault")

    let attr = ref.getSignerKeyAttr(publicKey: key)!
    return attr.weight
}
```


## get_pubsigner_path.cdc
 This gets the pubsigner path for different resources

```cadence
pub fun main(resourceName: String): PublicPath {
    switch resourceName {
        case "MasterMinter":
            return FiatToken.MasterMinterPubSigner
        case "Minter":
            return FiatToken.MinterPubSigner
        case "MinterController":
            return FiatToken.MinterControllerPubSigner
        case "Vault":
            return FiatToken.VaultPubSigner
        case "Pauser":
            return FiatToken.PauserPubSigner
        case "Blocklister":
            return FiatToken.BlocklisterPubSigner
        default:
            panic("Resource not supported")
    }
    return FiatToken.VaultPubSigner
}
```


## get_store_keys.cdc
 This script gets all the  stored public keys in a multiSigManager for a resource 


```cadence
pub fun main(resourceAddr: Address, resourcePubSignerPath: PublicPath): [String] {
    let resourceAcct = getAccount(resourceAddr)
    let ref = resourceAcct.getCapability(resourcePubSignerPath)
        .borrow<&{OnChainMultiSig.PublicSigner}>()
        ?? panic("Could not borrow Pub Signer reference to the Vault")

    return ref.getSignerKeys()
}
```


## get_tx_index.cdc
 This script gets the current TxIndex for payloads stored in multiSigManager in a resource 
 The new payload must be this value + 1


```cadence
pub fun main(resourceAddr: Address, resourcePubSignerPath: PublicPath): UInt64{
    let resourcAcct = getAccount(resourceAddr)
    let ref = resourcAcct.getCapability(resourcePubSignerPath)
        .borrow<&{OnChainMultiSig.PublicSigner}>()
        ?? panic("Could not borrow Pub Signer reference to Resource")

    return ref.getTxIndex()
}
```


# vault
## get_allowance.cdc
 This script reads the allowance field set in a vault for another resource 


```cadence
pub fun main(fromAcct: Address, toResourceId: UInt64): UFix64 {
    let acct = getAccount(fromAcct)
    let vaultRef = acct.getCapability(FiatToken.VaultAllowancePubPath)
        .borrow<&FiatToken.Vault{FiatTokenInterface.Allowance}>()
        ?? panic("Could not borrow Allowance reference to the Vault")
    return vaultRef.allowance(resourceId: toResourceId)!
}
```


## get_balance.cdc
 This script reads the balance field of an account's FiatToken Balance


```cadence
pub fun main(account: Address): UFix64 {
    let acct = getAccount(account)
    let vaultRef = acct.getCapability(FiatToken.VaultBalancePubPath)
        .borrow<&FiatToken.Vault{FungibleToken.Balance}>()
        ?? panic("Could not borrow Balance reference to the Vault")

    return vaultRef.balance
}
```


