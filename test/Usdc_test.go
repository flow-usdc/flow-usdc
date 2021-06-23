package main

import (
	"context"
	"os"
	"testing"

	// "github.com/onflow/cadence"
	"github.com/onflow/flow-go-sdk/client"
	"github.com/stretchr/testify/assert"
	"google.golang.org/grpc"
)

func setupTestEnvironment(t *testing.T) (context.Context, *client.Client) {
	ctx := context.Background()
	flowClient, err := client.New(os.Getenv("RPC_ADDRESS"), grpc.WithInsecure())
	assert.NoError(t, err)

	return ctx, flowClient
}

func TestGetUSDCTotalSupply(t *testing.T) {
	ctx, flowClient := setupTestEnvironment(t)

	supply, err := GetTotalSupply(ctx, flowClient)
	assert.NoError(t, err)
    assert.Equal(t, "10000.00000000", supply.String());
}
