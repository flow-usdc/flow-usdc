import Crypto

pub contract OnChainMultiSig {
    
    pub event NewPayloadAdded(resourceId: UInt64, txIndex: UInt64);
    pub event NewPayloadSigAdded(resourceId: UInt64, txIndex: UInt64);

    pub struct PayloadDetails {
        pub var txIndex: UInt64;
        pub var method: String;
        pub var args: [AnyStruct];
        
        init(txIndex: UInt64, method: String, args: [AnyStruct]) {
            self.txIndex = txIndex;
            self.method = method;
            self.args = args;
        }
    }
    
    pub struct PubKeyAttr{
        pub let sigAlgo: UInt8;
        pub let weight: UFix64
        
        init(sa: UInt8, w: UFix64) {
            self.sigAlgo = sa;
            self.weight = w;
        }
    }
    
    pub struct PayloadSigDetails {
        pub var keyListSignatures: [Crypto.KeyListSignature];
        pub var pubKeys: [String];

        init(keyListSignatures: [Crypto.KeyListSignature], pubKeys: [String]){
            self.keyListSignatures = keyListSignatures;
            self.pubKeys = pubKeys 
        }
    }

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
        pub fun addNewPayload(payload: PayloadDetails, publicKey: String, sig: [UInt8]);
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
        pub fun addNewPayload (resourceId: UInt64, payload: PayloadDetails, publicKey: String, sig: [UInt8]);
        pub fun addPayloadSignature (resourceId: UInt64, txIndex: UInt64, publicKey: String, sig: [UInt8]);
        pub fun readyForExecution(txIndex: UInt64): PayloadDetails?;
        pub fun configureKeys (pks: [String], kws: [UFix64]);
        pub fun removeKeys (pks: [String]);
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
        access(self) let payloads: {UInt64: PayloadDetails}

        /// Payload Signatures
        ///
        /// A Map of assigned Transaction Index and all the added signatures
        /// from signers in the `keyList`
        access(self) let payloadSigs: {UInt64: PayloadSigDetails}

        /// Returns the public keys store in this resource
        pub fun getSignerKeys(): [String] {
            return self.keyList.keys
        }

        /// Returns the attributes (algo, weight) for a given public key
        pub fun getSignerKeyAttr(publicKey: String): PubKeyAttr? {
            return self.keyList[publicKey]
        }
        
        /// Calculates the bytes of a given payload. 
        /// This is used to create the message to verify the signatures when
        /// they are added
        ///
        /// Note: Currently only support limited types 
        pub fun getSignableData(payload: PayloadDetails): [UInt8] {
            var s = payload.txIndex.toBigEndianBytes();
            s = s.concat(payload.method.utf8);
            for a in payload.args {
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
        pub fun addNewPayload (resourceId: UInt64, payload: PayloadDetails, publicKey: String, sig: [UInt8]) {

            // if the provided key is not in keyList, tx is rejected
            assert(self.keyList.containsKey(publicKey), message: "Public key is not a registered signer");

            // ensure that the signed txIndex is the next txIndex for this resource
            let txIndex = self.txIndex + UInt64(1);
            assert(payload.txIndex == txIndex, message: "Incorrect txIndex provided in paylaod")
            assert(!self.payloads.containsKey(txIndex), message: "Payload index already exist");
            self.txIndex = txIndex;

            // the first signature is at keyIndex 0 of the `KeyListSignature` 
            // Note: `keyIndex` must match the order of the Crypto.KeyList constructed during `verifySigners`
            let keyListSig = [Crypto.KeyListSignature(keyIndex: 0, signature: sig)]

            // check if the payloadSig is signed by one of the keys in `keyList`, preventing others from adding to storage
            // if approvalWeight is nil, the public key is not in the `keyList` or cannot be verified
            let approvalWeight = self.verifySigners(payload: payload, txIndex: nil, pks: [publicKey], sigs: keyListSig)
            if ( approvalWeight == nil) {
                panic ("Invalid signer")
            }

            // insert the payload and the first signature into the resource maps
            self.payloads.insert(key: txIndex, payload);

            let payloadSigDetails = PayloadSigDetails(
                    keyListSignatures: keyListSig,
                    pubKeys: [publicKey]
                )
            
            self.payloadSigs.insert(
                key: txIndex, 
                payloadSigDetails 
            )
            
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

            // this is a temp keyListSig list that is used to verify a single signature so we use `keyIndex` as 0
            // the correct `keyIndex` will overwrite the 0 after we know it is a valid signature
            var keyListSig = Crypto.KeyListSignature( keyIndex: 0, signature: sig)
            let approvalWeight = self.verifySigners(payload: nil, txIndex: txIndex, pks: [publicKey], sigs: [keyListSig])
            if ( approvalWeight == nil) {
                panic ("Invalid signer")
            }

            // create the correct `keyIndex` with the current length of all the stored signatures
            let currentIndex = self.payloadSigs[txIndex]!.keyListSignatures.length
            keyListSig = Crypto.KeyListSignature(keyIndex: currentIndex, signature: sig)
            
            // append signature to resource maps
            self.payloadSigs[txIndex]!.keyListSignatures.append(keyListSig);
            self.payloadSigs[txIndex]!.pubKeys.append(publicKey);

            emit NewPayloadSigAdded(resourceId: resourceId, txIndex: txIndex)
        }

        /// Checks to see if the total weights of the signers who signed the transaction 
        /// is sufficient for transaction to occur
        /// 
        /// The weight system is intended to be the same as accounts
        /// https://docs.onflow.org/concepts/accounts-and-keys/#weighted-keys
        ///
        /// Note: if the transaction is ready, the payload and signatures are removed from the maps and must be executed
        pub fun readyForExecution(txIndex: UInt64): PayloadDetails? {
            assert(self.payloads.containsKey(txIndex), message: "No payload for such index");
            let pks = self.payloadSigs[txIndex]!.pubKeys;
            let sigs = self.payloadSigs[txIndex]!.keyListSignatures;
            let approvalWeight = self.verifySigners(payload: nil, txIndex: txIndex, pks: pks, sigs: sigs)
            if (approvalWeight == nil) {
                return nil
            }
            if (approvalWeight! >= 1000.0) {
                self.payloadSigs.remove(key: txIndex)!;
                let pd = self.payloads.remove(key: txIndex)!;
                return pd
            } else {
                return nil
            }
        }
        
        /// Verifies the signature matches the `payload` or the `txIndex`, exclusively.
        /// We do not match the payload from a txIndex and the provided, therefore we reject caller if both are provided.
        /// 
        /// The total weight of valid sigatures is returned, if any.
        pub fun verifySigners (payload: PayloadDetails?, txIndex: UInt64?, pks: [String], sigs: [Crypto.KeyListSignature]): UFix64? {
            assert(payload != nil || txIndex != nil, message: "Cannot verify signature without payload or txIndex");
            assert(!(payload != nil && txIndex != nil), message: "can only verify signature for either payload or txIndex");
            assert(pks.length == sigs.length, message: "Cannot verify signatures without corresponding public keys");
            
            var totalAuthorisedWeight: UFix64 = 0.0;
            var keyList = Crypto.KeyList();

            // get the message of the signature
            var payloadInBytes: [UInt8] = []
            if (payload != nil) {
                payloadInBytes = self.getSignableData(payload: payload!);
            } else {
                let p = self.payloads[txIndex!];
                payloadInBytes = self.getSignableData(payload: p!);
            }

            var i = 0;
            while (i < pks.length) {
                // check if the public key is a registered signer
                if (self.keyList[pks[i]] == nil){
                    return nil
                }

                let pk = PublicKey(
                    publicKey: pks[i].decodeHex(),
                    signatureAlgorithm: SignatureAlgorithm(rawValue: self.keyList[pks[i]]!.sigAlgo) ?? panic ("Invalid signature algo")
                )
                
                keyList.add(
                    pk, 
                    hashAlgorithm: HashAlgorithm.SHA3_256,
                    weight: self.keyList[pks[i]]!.weight
                )
                totalAuthorisedWeight = totalAuthorisedWeight + self.keyList[pks[i]]!.weight
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
        
        init(publicKeys: [String], pubKeyAttrs: [PubKeyAttr]){
            assert( publicKeys.length == pubKeyAttrs.length, message: "Public keys must have associated attributes")
            self.payloads = {};
            self.payloadSigs = {};
            self.keyList = {};
            self.txIndex = 0;
            
            var i: Int = 0;
            while (i < publicKeys.length){
                self.keyList.insert(key: publicKeys[i], pubKeyAttrs[i]);
                i = i + 1;
            }
        }
    }
    
    pub fun createMultiSigManager(publicKeys: [String], pubKeyAttrs: [PubKeyAttr]): @Manager {
        return <- create Manager(publicKeys: publicKeys, pubKeyAttrs: pubKeyAttrs)
    }
}