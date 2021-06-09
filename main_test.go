package main

import (
	"context"
	"testing"

	"github.com/onflow/flow-go-sdk"
	"github.com/onflow/flow-go-sdk/client"
	"github.com/onflow/flow-go-sdk/crypto"
	"github.com/onflow/flow-go-sdk/examples"
	"github.com/onflow/flow-go-sdk/templates"
	"github.com/stretchr/testify/assert"
	"google.golang.org/grpc"
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
	ctx := context.Background()

	seed := []byte("elephant ears space cowboy octopus rodeo potato cannon pineapple")
	sk, _ := ECDSAKeygen(seed)

	flowClient, err := client.New("localhost:3569", grpc.WithInsecure())
	assert.NoError(t, err)

	// Using this examples.ServiceAccount helper here
	// https://github.com/onflow/flow-go-sdk/blob/master/examples/examples.go#L96
	payer, payerKey, payerSigner := examples.ServiceAccount(flowClient)

	accountKey := FlowAccountKeygen(sk)
	tx := templates.CreateAccount([]*flow.AccountKey{accountKey}, nil, payer)

	referenceBlockID := examples.GetReferenceBlockId(flowClient)

	tx.SetGasLimit(100).
		SetProposalKey(payer, payerKey.Index, payerKey.SequenceNumber).
		SetReferenceBlockID(referenceBlockID).
		SetPayer(payer)

	err = tx.SignEnvelope(payer, payerKey.Index, payerSigner)
	assert.NoError(t, err)

	err = flowClient.SendTransaction(ctx, *tx)
	assert.NoError(t, err)

	result, err := flowClient.GetTransactionResult(ctx, tx.ID())
	assert.NoError(t, err)

	if result.Status == flow.TransactionStatusSealed {
		for _, event := range result.Events {
			if event.Type == flow.EventAccountCreated {
				accountCreatedEvent := flow.AccountCreatedEvent(event)
				_ = accountCreatedEvent.Address()
			}
		}
	}

	blocks, err := flowClient.GetEventsForHeightRange(ctx, client.EventRangeQuery{
		Type:        "flow.AccountCreated",
		StartHeight: 0,
		EndHeight:   30,
	})
	assert.NoError(t, err)

	t.Log(blocks)
}
