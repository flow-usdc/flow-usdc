package main

import (
	"os"
	"testing"

    "github.com/flow-usdc/flow-usdc"
	"github.com/onflow/cadence"
	"github.com/stretchr/testify/assert"
)

// func TestAccountsCreated(t *testing.T) {
// 	ctx := context.Background()
// 	flowClient, err := client.New(os.Getenv("RPC_ADDRESS"), grpc.WithInsecure())
// 	assert.NoError(t, err)
//
// 	events, err := flowClient.GetEventsForHeightRange(ctx, client.EventRangeQuery{
// 		Type:        "flow.AccountCreated",
// 		StartHeight: 0,
// 		EndHeight:   10,
// 	})
// 	assert.NoError(t, err)
//
// 	// Question: Looks like there's a 1-block padding on either side of the events?
// 	t.Log(events)
// 	assert.Equal(t, len(events), 5)
// }


func TestMintingAndBurning(t *testing.T) {
	ctx, flowClient := util.SetupTestEnvironment(t)
	tokenAddress := os.Getenv("TOKEN_ACCOUNT_ADDRESS")
	skFT := os.Getenv("TOKEN_ACCOUNT_KEYS")
	amount := cadence.UFix64(500000000000)

	initialBalance, err := GetBalanceET(ctx, flowClient, tokenAddress)
	assert.NoError(t, err)

	result, err := MintTokens(ctx, flowClient, tokenAddress, amount, skFT)
	assert.NoError(t, err)
	t.Log(result.Events)

	balanceAfterMinting, err := GetBalanceET(ctx, flowClient, tokenAddress)
	assert.NoError(t, err)

	assert.Equal(t, balanceAfterMinting, initialBalance+amount)

	result, err = BurnTokens(ctx, flowClient, tokenAddress, amount, skFT)
	assert.NoError(t, err)
	t.Log(result.Events)

	balanceAfterBurning, err := GetBalanceET(ctx, flowClient, tokenAddress)
	assert.NoError(t, err)

	assert.Equal(t, balanceAfterBurning, initialBalance)
}

func TestAddVaultToAccount(t *testing.T) {
	ctx, flowClient := util.SetupTestEnvironment(t)
	address := os.Getenv("NEW_VAULTED_ACCOUNT_ADDRESS")
	sk := os.Getenv("NEW_VAULTED_ACCOUNT_SK")

	result, err := AddVaultToAccount(ctx, flowClient, address, sk)
	t.Log(result)
	assert.NoError(t, err)

	balance, err := GetBalanceET(ctx, flowClient, address)
	assert.NoError(t, err)
	assert.Equal(t, balance.String(), "0.00000000")
}

func TestNonVaultedAccount(t *testing.T) {
	ctx, flowClient := util.SetupTestEnvironment(t)
	address := os.Getenv("NON_VAULTED_ACCOUNT_ADDRESS")

	_, err := GetBalanceET(ctx, flowClient, address)
	assert.Error(t, err)
}

func TestTransferTokens(t *testing.T) {
	ctx, flowClient := util.SetupTestEnvironment(t)
	tokenSk := os.Getenv("TOKEN_ACCOUNT_KEYS")
	tokenAddress := os.Getenv("TOKEN_ACCOUNT_ADDRESS")

	newVaultedSk := os.Getenv("NEW_VAULTED_ACCOUNT_SK")
	newVaultedAddress := os.Getenv("NEW_VAULTED_ACCOUNT_ADDRESS")

	initialBalance, err := GetBalanceET(ctx, flowClient, tokenAddress)
	assert.NoError(t, err)

	// Transfer 1 token from FT minter to Account A
	result, err := TransferTokens(ctx, flowClient, 100000000, tokenAddress, newVaultedAddress, tokenSk)
	t.Log(result)
	assert.NoError(t, err)

	balanceA, err := GetBalanceET(ctx, flowClient, newVaultedAddress)
	assert.NoError(t, err)
	assert.Equal(t, balanceA.String(), "1.00000000")

	// Transfer the 1 token back from account A to FT minter
	result, err = TransferTokens(ctx, flowClient, 100000000, newVaultedAddress, tokenAddress, newVaultedSk)
	t.Log(result)
	assert.NoError(t, err)

	finalBalance, err := GetBalanceET(ctx, flowClient, tokenAddress)
	assert.NoError(t, err)
	assert.Equal(t, finalBalance, initialBalance)
}

func TestCreateNewAdmin(t *testing.T) {
	ctx, flowClient := util.SetupTestEnvironment(t)
	tokenSk := os.Getenv("TOKEN_ACCOUNT_KEYS")
	tokenAddress := os.Getenv("TOKEN_ACCOUNT_ADDRESS")
	newVaultedSk := os.Getenv("NEW_VAULTED_ACCOUNT_SK")
	newVaultedAddress := os.Getenv("NEW_VAULTED_ACCOUNT_ADDRESS")

	result, err := CreateAdmin(ctx, flowClient, tokenAddress, newVaultedAddress, tokenSk, newVaultedSk)
	t.Log(result)
	assert.NoError(t, err)

	result, err = MintTokens(ctx, flowClient, newVaultedAddress, 50000000000, newVaultedSk)
	t.Log(result)
	assert.NoError(t, err)

	balance, err := GetBalanceET(ctx, flowClient, newVaultedAddress)
	assert.NoError(t, err)
	assert.Equal(t, balance.String(), "500.00000000")

	result, err = BurnTokens(ctx, flowClient, newVaultedAddress, 40000000000, newVaultedSk)
	t.Log(result)
	assert.NoError(t, err)

	balance, err = GetBalanceET(ctx, flowClient, newVaultedAddress)
	assert.NoError(t, err)
	assert.Equal(t, balance.String(), "100.00000000")
}

func TestTransferToNonVaulted(t *testing.T) {
	ctx, flowClient := util.SetupTestEnvironment(t)
	tokenSk := os.Getenv("TOKEN_ACCOUNT_KEYS")
	tokenAddress := os.Getenv("TOKEN_ACCOUNT_ADDRESS")
	nonVaultedAddress := os.Getenv("NON_VAULTED_ACCOUNT_ADDRESS")

	// Transfer 1 token from FT minter to Account B, which has no vault
	_, err := TransferTokens(ctx, flowClient, 100000000, tokenAddress, nonVaultedAddress, tokenSk)
	assert.Error(t, err)
}
