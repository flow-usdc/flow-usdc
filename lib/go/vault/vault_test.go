package main

import (
	"os"
	"testing"

	util "github.com/flow-usdc/flow-usdc"
	"github.com/stretchr/testify/assert"
)

func TestAddVaultToAccount(t *testing.T) {
	ctx, flowClient := util.SetupTestEnvironment(t)
	address := os.Getenv("NEW_VAULTED_ACCOUNT_ADDRESS")
	sk := os.Getenv("NEW_VAULTED_ACCOUNT_SK")

	result, err := AddVaultToAccount(ctx, flowClient, address, sk)
	t.Log(result)
	assert.NoError(t, err)

	balance, err := util.GetBalance(ctx, flowClient, address)
	assert.NoError(t, err)
	assert.Equal(t, balance.String(), "0.00000000")
}

func TestNonVaultedAccount(t *testing.T) {
	ctx, flowClient := util.SetupTestEnvironment(t)
	address := os.Getenv("NON_VAULTED_ACCOUNT_ADDRESS")

	_, err := util.GetBalance(ctx, flowClient, address)
	assert.Error(t, err)
}

func TestTransferTokens(t *testing.T) {
	ctx, flowClient := util.SetupTestEnvironment(t)
	tokenSk := os.Getenv("TOKEN_ACCOUNT_KEYS")
	tokenAddress := os.Getenv("TOKEN_ACCOUNT_ADDRESS")

	newVaultedSk := os.Getenv("NEW_VAULTED_ACCOUNT_SK")
	newVaultedAddress := os.Getenv("NEW_VAULTED_ACCOUNT_ADDRESS")

	initialBalance, err := util.GetBalance(ctx, flowClient, tokenAddress)
	assert.NoError(t, err)

	result, err := TransferTokens(ctx, flowClient, 100000000, tokenAddress, newVaultedAddress, tokenSk)
	t.Log(result)
	assert.NoError(t, err)

	balanceA, err := util.GetBalance(ctx, flowClient, newVaultedAddress)
	assert.NoError(t, err)
	assert.Equal(t, "1.00000000", balanceA.String())

	// Transfer the 100 token back from account A to FT minter
	result, err = TransferTokens(ctx, flowClient, 100000000, newVaultedAddress, tokenAddress, newVaultedSk)
	t.Log(result)
	assert.NoError(t, err)

	finalBalance, err := util.GetBalance(ctx, flowClient, tokenAddress)
	assert.NoError(t, err)
	assert.Equal(t, finalBalance, initialBalance)
}

func TestTransferToNonVaulted(t *testing.T) {
	ctx, flowClient := util.SetupTestEnvironment(t)
	tokenSk := os.Getenv("TOKEN_ACCOUNT_KEYS")
	tokenAddress := os.Getenv("TOKEN_ACCOUNT_ADDRESS")
	nonVaultedAddress := os.Getenv("NON_VAULTED_ACCOUNT_ADDRESS")

	// Transfer 1 token from FT minter to Account B, which has no vault
	_, err := TransferTokens(ctx, flowClient, 1000, tokenAddress, nonVaultedAddress, tokenSk)
	assert.Error(t, err)
}
