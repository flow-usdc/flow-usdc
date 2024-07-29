/// OnChainMultiSig
///
/// THIS CONTRACT IS DEPRECATED
///
/// All the functionality has been removed
/// but the definitions have been kept in order
/// to allow the `FiatToken` upgrade to be compatible
///
/// You can see the 0.42 version with all the functionality
/// in the `deprecated/OnChainMultiSig_old.cdc` contract

access(all) contract OnChainMultiSig {

    access(all) resource interface PublicSigner {}
    
    access(all) resource interface KeyManager {}

    access(all) resource interface SignatureManager {}

    // ------- Structs -------
    access(all) struct PubKeyAttr {}
    
    // ------- Resources ------- 
    access(all) resource PayloadDetails {}
    
    access(all) resource Manager: SignatureManager {}
}