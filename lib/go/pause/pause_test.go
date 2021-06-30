package main

import (
	"os"
	"testing"

	util "github.com/flow-usdc/flow-usdc"
	"github.com/flow-usdc/flow-usdc/vault"
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

func TestPauserContractWithCap(t *testing.T) {
	ctx, flowClient := util.SetupTestEnvironment(t)
	pauserAddress := os.Getenv("PAUSER_ADDRESS")
	sk := os.Getenv("PAUSER_SK")

	result, err := PauseOrUnpauseContract(ctx, flowClient, pauserAddress, sk, 1)
	t.Log(result)
	assert.NoError(t, err)

	tokenSk := os.Getenv("TOKEN_ACCOUNT_KEYS")
	tokenAddress := os.Getenv("TOKEN_ACCOUNT_ADDRESS")
	newVaultedAddress := os.Getenv("NEW_VAULTED_ACCOUNT_ADDRESS")

	paused, pauseerr := GetPaused(ctx, flowClient)
	t.Log(result, "paused", paused.String())
	assert.NoError(t, pauseerr)
	assert.Equal(t, paused.String(), "true")

	_, terr := vault.TransferTokens(ctx, flowClient, 100000000, tokenAddress, newVaultedAddress, tokenSk)
	assert.Error(t, terr)
}

func TestPauserContractWithoutCap(t *testing.T) {
	ctx, flowClient := util.SetupTestEnvironment(t)
	nonPauserAddress := os.Getenv("NON_PAUSER_ADDRESS")
	sk := os.Getenv("NON_PAUSER_SK")

	result, err := CreatePauser(ctx, flowClient, nonPauserAddress, sk)
	t.Log(result)
	assert.NoError(t, err)

	_, pauseErr := PauseOrUnpauseContract(ctx, flowClient, nonPauserAddress, sk, 1)
	assert.Error(t, pauseErr)
}

func TestUnPauserContractWithCap(t *testing.T) {
	ctx, flowClient := util.SetupTestEnvironment(t)
	pauserAddress := os.Getenv("PAUSER_ADDRESS")
	sk := os.Getenv("PAUSER_SK")

	result, err := PauseOrUnpauseContract(ctx, flowClient, pauserAddress, sk, 0)
	t.Log(result)
	assert.NoError(t, err)

	tokenSk := os.Getenv("TOKEN_ACCOUNT_KEYS")
	tokenAddress := os.Getenv("TOKEN_ACCOUNT_ADDRESS")
	newVaultedAddress := os.Getenv("NEW_VAULTED_ACCOUNT_ADDRESS")

	_, terr := vault.TransferTokens(ctx, flowClient, 100000000, tokenAddress, newVaultedAddress, tokenSk)
	assert.NoError(t, terr)
}
