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

func TestClientConnection(t *testing.T) {
	ctx := context.Background()

	seed := []byte("elephant ears space cowboy octopus rodeo potato cannon pineapple")
	sk, _ := crypto.GeneratePrivateKey(crypto.ECDSA_P256, seed)

	flowClient, err := client.New("localhost:3569", grpc.WithInsecure())
	assert.NoError(t, err)

	// Using this examples.ServiceAccount helper here
	// https://github.com/onflow/flow-go-sdk/blob/master/examples/examples.go#L96
	payer, payerKey, payerSigner := examples.ServiceAccount(flowClient)

	pk := sk.PublicKey()

	accountKey := flow.NewAccountKey().
		SetPublicKey(pk).
		SetHashAlgo(crypto.SHA3_256).             // pair this key with the SHA3_256 hashing algorithm
		SetWeight(flow.AccountKeyWeightThreshold) // give this key full signing weight

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
