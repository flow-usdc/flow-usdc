package main

import (
	"context"
	"io/ioutil"
	"testing"

	"github.com/onflow/cadence"
	"github.com/onflow/flow-go-sdk/client"
	"github.com/stretchr/testify/assert"
	"google.golang.org/grpc"
)

func TestClientConnection(t *testing.T) {
	ctx := context.Background()

	flowClient, err := client.New("localhost:3569", grpc.WithInsecure())
	assert.NoError(t, err)

	// Using this examples.ServiceAccount helper here
	// https://github.com/onflow/flow-go-sdk/blob/master/examples/examples.go#L96
	//payer, payerKey, payerSigner := examples.ServiceAccount(flowClient)

	events, err := flowClient.GetEventsForHeightRange(ctx, client.EventRangeQuery{
		Type:        "flow.AccountCreated",
		StartHeight: 0,
		EndHeight:   10,
	})
	assert.NoError(t, err)

	// Question: Looks like there's a 1-block padding on either side of the events?
	assert.Equal(t, len(events), 5)

	script, err := ioutil.ReadFile("./contracts/scripts/get_balance.cdc")
	// script := []byte("pub fun main(): Int { return 1 }")

	value, err := flowClient.ExecuteScriptAtLatestBlock(ctx, script, nil)
	assert.NoError(t, err)

	ID := value.(cadence.Int)

	// convert to Go int type
	myID := ID.Int()

	t.Log(ID, myID)

}
