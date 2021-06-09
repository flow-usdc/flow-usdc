package main

import (
    "testing"
    "google.golang.org/grpc"
    "github.com/onflow/flow-go-sdk"
    "github.com/onflow/flow-go-sdk/crypto"
    "github.com/onflow/flow-go-sdk/client"
    "github.com/onflow/flow-go-sdk/examples"
    "github.com/onflow/flow-go-sdk/templates"
    "github.com/stretchr/testify/assert"
)

func TestECDSAKeygen(t *testing.T) {
    seed := []byte("elephant ears space cowboy octopus rodeo potato cannon pineapple")
    sk, err := ECDSAKeygen(seed)
    assert.NoError(t, err)

    assert.Equal(t, crypto.ECDSA_P256, sk.Algorithm())
    skString := "0x68ee617d9bf67a4677af80aaca5a090fcda80ff2f4dbc340e0e36201fa1f1d8c"
    assert.Equal(t, skString, sk.String())
}

func TestFlowAccountFromKeygen(t *testing.T) {
    seed := []byte("elephant ears space cowboy octopus rodeo potato cannon pineapple")
    sk, err := ECDSAKeygen(seed)
    assert.NoError(t, err)

    accountKey := FlowAccountKeygen(sk)
    pkString := "0x9cd98d436d111aab0718ab008a466d636a22ac3679d335b77e33ef7c52d9c8ce47cf5ad71ba38cedd336402aa62d5986dc224311383383c09125ec0636c0b042"
    assert.Equal(t, pkString, accountKey.PublicKey.String())
}

func TestClientConnection(t *testing.T) {
    seed := []byte("elephant ears space cowboy octopus rodeo potato cannon pineapple")
    sk, _ := ECDSAKeygen(seed)

    client, err := client.New("localhost:3569", grpc.WithInsecure())
    assert.NoError(t, err)

    // Using this examples.ServiceAccount helper here
    // https://github.com/onflow/flow-go-sdk/blob/master/examples/examples.go#L96
    payer, payerKey, _ := examples.ServiceAccount(client)

    accountKey := FlowAccountKeygen(sk)
    script := templates.CreateAccount([]*flow.AccountKey{accountKey}, nil, payer)

    tx := flow.NewTransaction().
        SetScript(script).
        SetGasLimit(100).
        SetProposalKey(payer, payerKey.Index, payerKey.SequenceNumber).
        SetPayer(payer)
}
