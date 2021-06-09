package main

import (
    "testing"
    "github.com/stretchr/testify/assert"
    "github.com/onflow/flow-go-sdk/crypto"
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

    flowAccount := FlowAccountKeygen(sk)
    pkString := "0x9cd98d436d111aab0718ab008a466d636a22ac3679d335b77e33ef7c52d9c8ce47cf5ad71ba38cedd336402aa62d5986dc224311383383c09125ec0636c0b042"
    assert.Equal(t, pkString, flowAccount.PublicKey.String())
}
