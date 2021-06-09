package main

// import "log"

// import "github.com/onflow/cadence"

import (
    "github.com/onflow/flow-go-sdk"
    "github.com/onflow/flow-go-sdk/crypto"
    // "github.com/onflow/flow-go-sdk/templates"
)

func ECDSAKeygen(seed []byte) (crypto.PrivateKey, error) {
    return crypto.GeneratePrivateKey(crypto.ECDSA_P256, seed)
}

func FlowAccountKeygen(privateKey crypto.PrivateKey) *flow.AccountKey {
    publicKey := privateKey.PublicKey()

    accountKey := flow.NewAccountKey().
        SetPublicKey(publicKey).
        SetHashAlgo(crypto.SHA3_256).               // pair this key with the SHA3_256 hashing algorithm
        SetWeight(flow.AccountKeyWeightThreshold)   // give this key full signing weight

   return accountKey
}

func main() {
    seed := []byte("elephant ears space cowboy octopus rodeo potato cannon pineapple")
    pk, _ := ECDSAKeygen(seed) // TODO err handling

    FlowAccountKeygen(pk)
}
