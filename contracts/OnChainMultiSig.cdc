import Crypto

pub contract OnChainMultiSig {
    
    pub event NewPayloadAdded(resourceId: UInt64, txIndex: UInt64);
    pub event NewPayloadSigAdded(resourceId: UInt64, txIndex: UInt64);

    /// Argument for payload
    pub struct PayloadArg {
        pub let type: Type;
        pub let value: AnyStruct;
        
        init(t: Type, v: AnyStruct) {
            self.type = t;
            self.value = v
        }
    }

    pub struct PayloadDetails {
        pub var method: String;
        pub var args: [PayloadArg];
        
        init(method: String, args: [PayloadArg]) {
            self.method = method;
            self.args = args;
        }

    }

    pub struct KeyListElement {
        // String in hex to be decoded as [UInt8]
        pub let publicKey: String;
        pub let sigAlgo: UInt8;
        pub let weight: UFix64
        
        init(pk: String, sa: UInt8, w: UFix64) {
            self.publicKey = pk;
            self.sigAlgo = sa;
            self.weight = w;
        }
    }

    pub resource interface PublicSigner {
        // the first [UInt8] in the signable data will be the method
        // follow by the args if args are not resources
        // TODO: resource? 
        pub fun addNewPayload(payload: PayloadDetails, keyListIndex: Int, sig: [UInt8]);
        pub fun addPayloadSignature (txIndex: UInt64, keyListIndex: Int, sig: [UInt8]);
        pub fun executeTx(txIndex: UInt64);
    }
    
    pub struct interface SignatureManager {
        pub fun getSignableData(payload: PayloadDetails): [UInt8];
        pub fun addNewPayload (resourceId: UInt64, payload: PayloadDetails, keyListIndex: Int, sig: [UInt8]): SignatureStore;
        pub fun addPayloadSignature (resourceId: UInt64, txIndex: UInt64, keyListIndex: Int, sig: [UInt8]): SignatureStore;
        pub fun readyForExecution(txIndex: UInt64): PayloadDetails?;
    }
    
    pub struct SignatureStore {
        // Keylist index
        pub(set) var keyListIndex: UInt64;
        
        // Transaction index
        pub(set) var txIndex: UInt64;

        // Signers and their weights
        pub let keyList: {UInt64: KeyListElement};

        // map of an assigned index and the payload
        // payload in this case is the script and argument
        pub var payloads: {UInt64: PayloadDetails}

        pub var payloadSigs: {UInt64: [Crypto.KeyListSignature]}

        init(initialSigners: [KeyListElement]){
            self.payloads = {};
            self.payloadSigs = {};
            self.keyList = {};
            self.keyListIndex = 0;
            self.txIndex = 0;
            
           for e in initialSigners {
               self.keyList.insert(key: self.keyListIndex, e);
               self.keyListIndex = self.keyListIndex + 1 as UInt64;
           }
        }
    }

    pub struct Manager: SignatureManager {
        
        pub var signatureStore: SignatureStore;
    

        pub fun getSignableData(payload: PayloadDetails): [UInt8] {
            let s = payload.method.utf8;
            for a in payload.args {
                var b: [UInt8] = [];
                switch a.type {
                    case Type<String>():
                        let temp = a.value as? String;
                        b = temp!.utf8; 
                    case Type<UInt64>():
                        let temp = a.value as? UInt64;
                        b = temp!.toBigEndianBytes(); 
                    case Type<UFix64>():
                        let temp = a.value as? UFix64;
                        b = temp!.toBigEndianBytes(); 
                    case Type<Address>():
                        let temp = a.value as? Address;
                        b = temp!.toBytes(); 
                    default:
                        panic ("Payload arg type not supported")
                }
                s.concat(b);
            }
            return s; 
        }
        
        // Currently not supporting MultiSig
        pub fun addKey (newKeyListElement: KeyListElement): SignatureStore {
            self.signatureStore.keyList.insert(key: self.signatureStore.keyListIndex, newKeyListElement);
            self.signatureStore.keyListIndex = self.signatureStore.keyListIndex + 1 as UInt64;
            return self.signatureStore
        }

        // Currently not supporting MultiSig
        pub fun removeKey (keyIndex: UInt64, keyListElement: KeyListElement): SignatureStore {
            pre {
                self.signatureStore.keyList.containsKey(keyIndex): "keylist does not contain such key index"
            }
            self.signatureStore.keyList.remove(key: keyIndex);
            return self.signatureStore
        }
        
        pub fun addNewPayload (resourceId: UInt64, payload: PayloadDetails, keyListIndex: Int, sig: [UInt8]): SignatureStore {
            // 1. check if the payloadSig is signed by one of the account's keys, preventing others from adding to storage

            // 2. increment index
            let txIndex = self.signatureStore.txIndex.saturatingAdd(1);
            self.signatureStore.txIndex = txIndex;

            // 3. call addPayloadSig to store the first sig for the index
            assert(!self.signatureStore.payloads.containsKey(txIndex), message: "Payload index already exist");
            self.signatureStore.payloads.insert(key: txIndex, payload);
            
            let sigs = [Crypto.KeyListSignature( keyIndex: keyListIndex, signature: sig)]
            self.signatureStore.payloadSigs.insert(
                key: txIndex, 
                sigs
            )
            
            emit NewPayloadAdded(resourceId: resourceId, txIndex: txIndex)
            return self.signatureStore
        }

        pub fun addPayloadSignature (resourceId: UInt64, txIndex: UInt64, keyListIndex: Int, sig: [UInt8]): SignatureStore {
            // 1. check if the the signer is the accounting owning this signer by using data as the one in payloads
            // 2. add to the sig
            // 3. if weight of all the signatures above threshold, call executeTransaction
            emit NewPayloadSigAdded(resourceId: resourceId, txIndex: txIndex)
            return self.signatureStore
        }

        pub fun readyForExecution(txIndex: UInt64): PayloadDetails? {
            assert(self.signatureStore.payloads.containsKey(txIndex), message: "No payload for such index");
            // 1. returns the signed weights of the particular transaction by Transaction index
            // 2. if not enough weight etc, return nil
            let pd = self.signatureStore.payloads.remove(key: txIndex)!;
            return pd;
        }
        
        
        init(sigStore: SignatureStore) {
            self.signatureStore = sigStore;
        }
            
    }
}