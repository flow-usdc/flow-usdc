import Crypto
import FungibleToken from "./FungibleToken.cdc"

pub contract OnChainMultiSig {
    
    //
    // ------- Events ------- 
    //
    pub event NewPayloadAdded(resourceId: UInt64, txIndex: UInt64);
    pub event NewPayloadSigAdded(resourceId: UInt64, txIndex: UInt64);

    //
    // ------- Interfaces ------- 
    //

    /// Public Signer
    /// 
    /// These interfaces is intended for public usage, a resource that stores the @Manager should implement
    ///
    /// 1. addNewPayload: add new transaction payload to the signature store waiting for others to sign
    /// 2. addPayloadSignature: add signature to store for existing paylaods by payload index
    /// 3. executeTx: attempt to execute the transaction at a given index after required signatures have been added
    /// 4. UUID: gets the uuid of this resource 
    /// 5. getTxIndex: gets the sequentially assigned current txIndex of multisig pending tx of this resource 
    /// 6. getSignerKeys: gets the list of public keys for the resource's multisig signers 
    /// 7. getSignerKeyAttr: gets the stored key attributes 
    /// Interfaces 1&2 use `OnChainMultiSig.Manager` resource for code implementation
    /// Interface 3 needs to be implemented specifically for each resource
    /// Interfaces 4-7 are useful information to interact with the multiSigManager 
    ///
    /// For example, a `Vault` resource with onchain multisig capabilities should implement these interfaces,
    /// see example in "./MultiSigFlowToken"
    pub resource interface PublicSigner {
        pub fun addNewPayload(payload: @PayloadDetails, publicKey: String, sig: [UInt8]);
        pub fun addPayloadSignature (txIndex: UInt64, publicKey: String, sig: [UInt8]);
        pub fun executeTx(txIndex: UInt64): @AnyResource?;
        pub fun UUID(): UInt64;
        pub fun getTxIndex(): UInt64;
        pub fun getSignerKeys(): [String];
        pub fun getSignerKeyAttr(publicKey: String): PubKeyAttr?;
    }
    
    /// Key Manager
    ///
    /// Optional interfaces for owner of the vault to add / remove keys in @Manager. 
    pub resource interface KeyManager {
        pub fun addKeys( multiSigPubKeys: [String], multiSigKeyWeights: [UFix64]);
        pub fun removeKeys( multiSigPubKeys: [String]);
    }
    
    /// Signature Manager
    ///
    /// These interfaces are minimum required for implementors of `PublicSigner` to work
    /// with the @Manager resource
    pub resource interface SignatureManager {
        pub fun getSignerKeys(): [String];
        pub fun getSignerKeyAttr(publicKey: String): PubKeyAttr?;
        pub fun addNewPayload (resourceId: UInt64, payload: @PayloadDetails, publicKey: String, sig: [UInt8]);
        pub fun addPayloadSignature (resourceId: UInt64, txIndex: UInt64, publicKey: String, sig: [UInt8]);
        pub fun readyForExecution(txIndex: UInt64): @PayloadDetails?;
        pub fun configureKeys (pks: [String], kws: [UFix64]);
        pub fun removeKeys (pks: [String]);
    }
    
    //
    // ------- Struct ------- 
    //

    pub struct PubKeyAttr{
        pub let sigAlgo: UInt8;
        pub let weight: UFix64
        
        init(sa: UInt8, w: UFix64) {
            self.sigAlgo = sa;
            self.weight = w;
        }
    }

    //
    // ------- Resources ------- 
    //

    /// PayloadDetails
    ///
    /// A resource that contains the method, args, resource required to execute a transaction
    /// The signatures from the signers are also stored here to be verified if enough signers
    /// have signed
    ///
    /// Payload Details is not exposed outside of @Manager until it is 
    /// returned when the transaction is ready in `readyForExecution`
    /// Once it has been returned, it is no longer signable
    pub resource PayloadDetails {
        pub var txIndex: UInt64;
        pub var method: String;
        // This is settable because we need to swap the vault out AFTER
        // it has been returned to use it. 
        pub(set) var rsc: @AnyResource?;
        access(self) let args: [AnyStruct];
        /// Payload Signatures
        ///
        /// All the added signatures from signers in the `keyList`
        access(contract) let keyListSignatures: [Crypto.KeyListSignature];
        access(contract) let pubKeys: [String];
        
        pub fun getArg(i: UInt): AnyStruct? {
            return self.args[i]
        }      

        /// Calculates the bytes of a given payload. 
        /// This is used to create the message to verify the signatures when
        /// they are added
        ///
        /// Note: Currently only support limited types 
        pub fun getSignableData(): [UInt8] {
            var s = self.txIndex.toBigEndianBytes();
            s = s.concat(self.method.utf8);
            for a in self.args {
                var b: [UInt8] = [];
                switch a.getType() {
                    case Type<String>():
                        let temp = a as? String;
                        b = temp!.utf8; 
                    case Type<UInt64>():
                        let temp = a as? UInt64;
                        b = temp!.toBigEndianBytes(); 
                    case Type<UFix64>():
                        let temp = a as? UFix64;
                        b = temp!.toBigEndianBytes(); 
                    case Type<Address>():
                        let temp = a as? Address;
                        b = temp!.toBytes(); 
                    default:
                        panic ("Payload arg type not supported")
                }
                s = s.concat(b);
            }
            return s; 
        }
        
        /// Verifies the signature matches the `payload`
        /// 
        /// The total weight of valid sigatures is returned, if any.
        pub fun verifySigners (pks: [String], sigs: [Crypto.KeyListSignature], currentKeyList: {String: PubKeyAttr}): UFix64? {
            assert(pks.length == sigs.length, message: "Cannot verify signatures without corresponding public keys");
            
            var totalAuthorisedWeight: UFix64 = 0.0;
            var keyList = Crypto.KeyList();

            // get the message of the signature
            var payloadInBytes: [UInt8] = self.getSignableData();

            var i = 0;
            while (i < pks.length) {
                // check if the public key is a registered signer
                if (currentKeyList[pks[i]] == nil){
                    return nil
                }

                let pk = PublicKey(
                    publicKey: pks[i].decodeHex(),
                    signatureAlgorithm: SignatureAlgorithm(rawValue: currentKeyList[pks[i]]!.sigAlgo) ?? panic ("Invalid signature algo")
                )
                
                keyList.add(
                    pk, 
                    hashAlgorithm: HashAlgorithm.SHA3_256,
                    weight: currentKeyList[pks[i]]!.weight
                )
                totalAuthorisedWeight = totalAuthorisedWeight + currentKeyList[pks[i]]!.weight
                i = i + 1;
            }
            
            let isValid = keyList.verify(
                signatureSet: sigs,
                signedData: payloadInBytes,
            )
            if (isValid) {
                return totalAuthorisedWeight
            } else {
                return nil
            }
        }
        
        /// addSignature
        ///
        /// Once signature has been verified, it can be added here
        pub fun addSignature(keyListSig: Crypto.KeyListSignature, publicKey: String){
            self.keyListSignatures.append(keyListSig);
            self.pubKeys.append(publicKey);
        }
        
        destroy () {
            destroy self.rsc
        }

        init(txIndex: UInt64, method: String, args: [AnyStruct], rsc: @AnyResource?) {
            self.args = args;
            self.txIndex = txIndex;
            self.method = method;
            self.keyListSignatures = []
            self.pubKeys = []
            
            // Checks that the resource details are within the args
            // This ensures that new signatures signers are aware of the details.
            // Note: This is currently only for FungibleToken, not generic 
            let r: @AnyResource <- rsc ?? nil
            if r != nil && r.isInstance(Type<@FungibleToken.Vault>()) {
                    let vault <- r as! @FungibleToken.Vault
                    assert(vault.balance == args[0] as! UFix64, message: "First arguement must be balance of Vault")
                    self.rsc <- vault;
            } else {
                self.rsc <- r;
            }
        }
    }
    
    /// Manager
    ///
    /// The main resource that stores, keys, payloads and signature before all signatures are collected / executed
    pub resource Manager: SignatureManager {
        
        /// Transaction Index
        ///
        /// The sequenctial identifier for each payload stored.
        /// Newly added payload increments this index. 
        pub var txIndex: UInt64;

        /// Key List
        /// 
        /// Stores the public keys and their respected attributes.
        /// Only public keys stored here can add payload or payload signatures.
        ///
        /// Public keys stored in hex encoded string format without prefix "0x"
        access(self) let keyList: {String: PubKeyAttr};

        /// Payloads
        ///
        /// A Map of an assigned Transaction Index and the Payload represented 
        /// by `PayloadDetails`
        access(self) let payloads: @{UInt64: PayloadDetails}


        /// Returns the public keys store in this resource
        pub fun getSignerKeys(): [String] {
            return self.keyList.keys
        }

        /// Returns the attributes (algo, weight) for a given public key
        pub fun getSignerKeyAttr(publicKey: String): PubKeyAttr? {
            return self.keyList[publicKey]
        }
        
        pub fun removePayload(txIndex: UInt64): @PayloadDetails {
            assert(self.payloads.containsKey(txIndex), message: "no payload at txIndex")
            return <- self.payloads.remove(key: txIndex)!
        }
        
        /// Add / replace stored public keys and respected attributes
        /// from `keyList`
        pub fun configureKeys (pks: [String], kws: [UFix64]) {
            var i: Int =  0;
            while (i < pks.length) {
                let a = PubKeyAttr(sa: 1, w: kws[i])
                self.keyList.insert(key: pks[i], a)
                i = i + 1;
            }
        }

        /// Removed stored public keys and respected attributes
        /// from `keyList`
        pub fun removeKeys (pks: [String]) {
            var i: Int =  0;
            while (i < pks.length) {
                self.keyList.remove(key:pks[i])
                i = i + 1;
            }
        }
        
        /// Add a new payload, potentially requiring additional signatures from other signers
        /// 
        /// `resourceId`: the uuid of the resource that stores this resource
        /// `payload`   : the payload of the transaction represented by the `PayloadDetails` struct
        /// `publicKey` : the public key (must be in the keyList) that signed the `sig`
        /// `sig`       : the signature where the message is the signable data of the payload
        pub fun addNewPayload (resourceId: UInt64, payload: @PayloadDetails, publicKey: String, sig: [UInt8]) {

            // if the provided key is not in keyList, tx is rejected
            assert(self.keyList.containsKey(publicKey), message: "Public key is not a registered signer");

            // ensure that the signed txIndex is the next txIndex for this resource
            let txIndex = self.txIndex + UInt64(1);
            assert(payload.txIndex == txIndex, message: "Incorrect txIndex provided in paylaod")
            assert(!self.payloads.containsKey(txIndex), message: "Payload index already exist");
            self.txIndex = txIndex;

            // the first signature is at keyIndex 0 of the `KeyListSignature` 
            // Note: `keyIndex` must match the order of the Crypto.KeyList constructed during `verifySigners`
            let keyListSig = Crypto.KeyListSignature(keyIndex: 0, signature: sig)

            // check if the payloadSig is signed by one of the keys in `keyList`, preventing others from adding to storage
            // if approvalWeight is nil, the public key is not in the `keyList` or cannot be verified
            let approvalWeight = payload.verifySigners(pks: [publicKey], sigs: [keyListSig], currentKeyList: self.keyList)
            if ( approvalWeight == nil) {
                panic ("Invalid signer")
            }
            
            // insert the payload and the first signature into the resource maps
            payload.addSignature(keyListSig: keyListSig, publicKey: publicKey)
            self.payloads[txIndex] <-! payload;

            emit NewPayloadAdded(resourceId: resourceId, txIndex: txIndex)
        }

        /// Add a new payload signature to an existing stored payload identified by the `txIndex`
        /// 
        /// `resourceId`: the uuid of the resource that stores this resource
        /// `txIndex`   : the transaction index where the payload was added
        /// `publicKey` : the public key (must be in the keyList) that signed the `sig`
        /// `sig`       : the signature where the message is the signable data of the payload
        pub fun addPayloadSignature (resourceId: UInt64, txIndex: UInt64, publicKey: String, sig: [UInt8]) {
            assert(self.payloads.containsKey(txIndex), message: "Payload has not been added");
            assert(self.keyList.containsKey(publicKey), message: "Public key is not a registered signer");

            let p <- self.payloads.remove(key: txIndex)!;
            let currentIndex = p.keyListSignatures.length
            var i = 0;
            while i < currentIndex {
                if p.pubKeys[i] == publicKey {
                    break
                }
                i = i + 1;
            } 
            if i < currentIndex {
                self.payloads[txIndex] <-! p;
                panic ("Signature already added for this txIndex")
            } else {
                // this is a temp keyListSig list that is used to verify a single signature so we use `keyIndex` as 0
                // the correct `keyIndex` will overwrite the 0 after we know it is a valid signature
                var keyListSig = Crypto.KeyListSignature( keyIndex: 0, signature: sig)
                    let approvalWeight = p.verifySigners( pks: [publicKey], sigs: [keyListSig], currentKeyList: self.keyList)
                    if ( approvalWeight == nil) {
                        self.payloads[txIndex] <-! p;
                        panic ("Invalid signer")
                    } else {
                        // create the correct `keyIndex` with the current length of all the stored signatures
                        keyListSig = Crypto.KeyListSignature(keyIndex: currentIndex, signature: sig)

                        // append signature to resource maps
                        p.addSignature(keyListSig: keyListSig, publicKey: publicKey)
                        self.payloads[txIndex] <-! p;

                        emit NewPayloadSigAdded(resourceId: resourceId, txIndex: txIndex)
                    }
            }

        }

        /// Checks to see if the total weights of the signers who signed the transaction 
        /// is sufficient for transaction to occur
        /// 
        /// The weight system is intended to be the same as accounts
        /// https://docs.onflow.org/concepts/accounts-and-keys/#weighted-keys
        ///
        /// Note: if the transaction is ready, the payload and signatures are removed from the maps and must be executed
        pub fun readyForExecution(txIndex: UInt64): @PayloadDetails? {
            assert(self.payloads.containsKey(txIndex), message: "No payload for such index");
            let p <- self.payloads.remove(key: txIndex)!;
            let approvalWeight = p.verifySigners( pks: p.pubKeys, sigs: p.keyListSignatures, currentKeyList: self.keyList)
            if (approvalWeight! >= 1000.0) {
                return <- p
            } else {
                self.payloads[txIndex] <-! p;
                return nil
            }
        }

        destroy () {
            destroy self.payloads
        }
        
        init(publicKeys: [String], pubKeyAttrs: [PubKeyAttr]){
            assert( publicKeys.length == pubKeyAttrs.length, message: "Public keys must have associated attributes")
            self.payloads <- {};
            self.keyList = {};
            self.txIndex = 0;
            
            var i: Int = 0;
            while (i < publicKeys.length){
                self.keyList.insert(key: publicKeys[i], pubKeyAttrs[i]);
                i = i + 1;
            }
        }
    }

    // 
    // ------- Functions --------
    //
        
    pub fun createMultiSigManager(publicKeys: [String], pubKeyAttrs: [PubKeyAttr]): @Manager {
        return <- create Manager(publicKeys: publicKeys, pubKeyAttrs: pubKeyAttrs)
    }

    pub fun createPayload(txIndex: UInt64, method: String, args: [AnyStruct], rsc: @AnyResource?): @PayloadDetails{
        return <- create PayloadDetails(txIndex: txIndex, method: method, args: args, rsc: <-rsc)
    }
}