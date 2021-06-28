package main

import (
	"os"
	"testing"

	util "github.com/flow-usdc/flow-usdc"
	"github.com/stretchr/testify/assert"
	// "github.com/onflow/cadence"
)

func TestCreatePauser(t *testing.T) {
	ctx, flowClient := util.SetupTestEnvironment(t)
	address := os.Getenv("PAUSER_ADDRESS")
	sk := os.Getenv("PAUSER_SK")

	result, err := CreatePauser(ctx, flowClient, address, sk)
	t.Log(result)
	assert.NoError(t, err)

	//canBorrow, err := util.CheckPublicCapability(ctx, flowClient, address, "UsdcPauseCapReceiver")
	//assert.Equal(t, cadence.NewBool(true), canBorrow)

}

func TestSetPauserCapability(t *testing.T) {
	ctx, flowClient := util.SetupTestEnvironment(t)
	ownerAddress := os.Getenv("TOKEN_ACCOUNT_ADDRESS")
	pauserAddress := os.Getenv("PAUSER_ADDRESS")
	sk := os.Getenv("TOKEN_ACCOUNT_KEYS")

	result, err := SetPauserCapability(ctx, flowClient, pauserAddress, ownerAddress, sk)
	t.Log(result)
	assert.NoError(t, err)
}
