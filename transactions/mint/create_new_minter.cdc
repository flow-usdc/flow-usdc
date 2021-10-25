// This script creates a new Minter resource.
// If no onchain-multisig is required, empty publicKeys and pubKeyWeights array can be used.
// If account already has a Minter, it will remove it and create a new one. 
// 
// Minter are granted allowance by the UUID.
// If a new one is created, the UUID will be different and will not have the same allowance. 

import FungibleToken from 0x{{.FungibleToken}}
import FiatToken from 0x{{.FiatToken}}
import OnChainMultiSig from 0x{{.OnChainMultiSig}}

transaction(minterAddr: Address, publicKeys: [String], pubKeyWeights: [UFix64], multiSigAlgos: [UInt8]) {
    prepare (minter: AuthAccount) {
        
        // Check and return if they already have a minter resource
        //assert(minter.borrow<&FiatToken.Minter>(from: FiatToken.MinterStoragePath) != nil, message: "account already has minter resource")
        // DANGER: Remove existing minter if present
        if minter.borrow<&FiatToken.Minter>(from: FiatToken.MinterStoragePath) != nil {
            minter.unlink(FiatToken.MinterUUIDPubPath)
            minter.unlink(FiatToken.MinterPubSigner)
            let m <- minter.load<@FiatToken.Minter>(from: FiatToken.MinterStoragePath) 
            destroy m
        }

        // Ensure that there is a Provider private capability for the account
        // Ideally the user would do this in a separate step, but it is hgere for convenience
        if ! minter.getCapability<&FiatToken.Vault{FungibleToken.Provider}>(FiatToken.VaultProviderPrivPath).check() {
            minter.link<&FiatToken.Vault{FungibleToken.Provider}>(FiatToken.VaultProviderPrivPath, target: FiatToken.VaultStoragePath)
        }
        let vaultProvider =  minter.getCapability<&FiatToken.Vault{FungibleToken.Provider}>(FiatToken.VaultProviderPrivPath)

        var i = 0;
        let pka: [OnChainMultiSig.PubKeyAttr] = []
        while i < pubKeyWeights.length {
            let a = OnChainMultiSig.PubKeyAttr(sa: multiSigAlgos[i], w: pubKeyWeights[i])
            pka.append(a)
            i = i + 1;
        }

        minter.save(<- FiatToken.createNewMinter(publicKeys: publicKeys, pubKeyAttrs: pka, vaultCapability: vaultProvider), to: FiatToken.MinterStoragePath);

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
