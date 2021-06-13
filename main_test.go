package main

import (
	"context"
	"os"
	"testing"

	"github.com/onflow/flow-go-sdk"
	"github.com/onflow/flow-go-sdk/client"
	"github.com/stretchr/testify/assert"
	"google.golang.org/grpc"
)

func TestAccountsCreated(t *testing.T) {
	ctx := context.Background()
	flowClient, err := client.New(os.Getenv("RPC_ADDRESS"), grpc.WithInsecure())
	assert.NoError(t, err)

	events, err := flowClient.GetEventsForHeightRange(ctx, client.EventRangeQuery{
		Type:        "flow.AccountCreated",
		StartHeight: 0,
		EndHeight:   10,
	})
	assert.NoError(t, err)

	// Question: Looks like there's a 1-block padding on either side of the events?
	assert.Equal(t, len(events), 5)
}

func TestGetSupply(t *testing.T) {
	ctx := context.Background()
	flowClient, err := client.New(os.Getenv("RPC_ADDRESS"), grpc.WithInsecure())
	assert.NoError(t, err)

	supply, err := GetSupply(ctx, flowClient)
	assert.Equal(t, supply.String(), "1000.00000000")
}

func TestGetBalance(t *testing.T) {
	ctx := context.Background()
	c, err := client.New(os.Getenv("RPC_ADDRESS"), grpc.WithInsecure())
	assert.NoError(t, err)

	address := flow.HexToAddress(os.Getenv("TOKEN_ACCOUNT_ADDRESS"))
	balance, err := GetBalance(ctx, c, address)
	assert.Equal(t, balance.String(), "1000.00000000")
}

func TestAddVaultToAccount(t *testing.T) {
	ctx := context.Background()
	flowClient, err := client.New(os.Getenv("RPC_ADDRESS"), grpc.WithInsecure())
	assert.NoError(t, err)

	skString := "58125e2c18823b7914c625500e76e3006aa2e936bc9b9169f77ab951e84edefd"
	accountA, err := flowClient.GetAccount(ctx, flow.HexToAddress("0x179b6b1cb6755e31"))
	err = AddVaultToAccount(ctx, flowClient, accountA, skString)
	assert.NoError(t, err)

	balance, err := GetBalance(ctx, flowClient, accountA.Address)
	assert.NoError(t, err)
	assert.Equal(t, balance.String(), "0.00000000")
}

func TestNonVaultedAccount(t *testing.T) {
	ctx := context.Background()
	flowClient, err := client.New(os.Getenv("RPC_ADDRESS"), grpc.WithInsecure())
	assert.NoError(t, err)

	_, err = GetBalance(ctx, flowClient, flow.HexToAddress("0xf3fcd2c1a78f5eee"))
	assert.Error(t, err)
}

func TestTransferTokens(t *testing.T) {
	ctx := context.Background()
	flowClient, err := client.New(os.Getenv("RPC_ADDRESS"), grpc.WithInsecure())
	assert.NoError(t, err)

	skFT := os.Getenv("TOKEN_ACCOUNT_KEYS")
	address := flow.HexToAddress(os.Getenv("TOKEN_ACCOUNT_ADDRESS"))
	accountFT, err := flowClient.GetAccount(ctx, address)
	assert.NoError(t, err)

	skA := "58125e2c18823b7914c625500e76e3006aa2e936bc9b9169f77ab951e84edefd"
	accountA, err := flowClient.GetAccount(ctx, flow.HexToAddress("0x179b6b1cb6755e31"))
	assert.NoError(t, err)

	// Transfer 1 token from FT minter to Account A
	result, err := TransferTokens(ctx, flowClient, 100000000, accountFT, accountA.Address, skFT)
	t.Log(result)
	assert.NoError(t, err)

	balanceA, err := GetBalance(ctx, flowClient, flow.HexToAddress("0x179b6b1cb6755e31"))
	assert.NoError(t, err)
	assert.Equal(t, balanceA.String(), "1.00000000")

	// Transfer the 1 token back from account A to FT minter
	result, err = TransferTokens(ctx, flowClient, 100000000, accountA, accountFT.Address, skA)
	t.Log(result)
	assert.NoError(t, err)

	address = flow.HexToAddress(os.Getenv("TOKEN_ACCOUNT_ADDRESS"))
	balanceFT, err := GetBalance(ctx, flowClient, address)
	assert.NoError(t, err)
	assert.Equal(t, balanceFT.String(), "1000.00000000")
}

func TestTransferToNonVaulted(t *testing.T) {
	ctx := context.Background()
	flowClient, err := client.New(os.Getenv("RPC_ADDRESS"), grpc.WithInsecure())
	assert.NoError(t, err)

	skFT := os.Getenv("TOKEN_ACCOUNT_KEYS")
	address := flow.HexToAddress(os.Getenv("TOKEN_ACCOUNT_ADDRESS"))
	accountFT, err := flowClient.GetAccount(ctx, address)
	assert.NoError(t, err)

	accountB, err := flowClient.GetAccount(ctx, flow.HexToAddress("0xf3fcd2c1a78f5eee"))
	assert.NoError(t, err)

	// Transfer 1 token from FT minter to Account B, which has no vault
	result, err := TransferTokens(ctx, flowClient, 100000000, accountFT, accountB.Address, skFT)
	assert.Error(t, result.Error)
}

func TestMintTokens(t *testing.T) {
	ctx := context.Background()
	flowClient, err := client.New(os.Getenv("RPC_ADDRESS"), grpc.WithInsecure())
	assert.NoError(t, err)

	skFT := os.Getenv("TOKEN_ACCOUNT_KEYS")
	address := flow.HexToAddress(os.Getenv("TOKEN_ACCOUNT_ADDRESS"))
	accountFT, err := flowClient.GetAccount(ctx, address)
	assert.NoError(t, err)

	result, err := MintTokens(ctx, flowClient, accountFT, 50000000000, skFT)
	assert.NoError(t, result.Error)

	balanceFT, err := GetBalance(ctx, flowClient, address)
	assert.NoError(t, err)
	assert.Equal(t, balanceFT.String(), "1500.00000000")
}

func TestBurnTokens(t *testing.T) {
	ctx := context.Background()
	flowClient, err := client.New(os.Getenv("RPC_ADDRESS"), grpc.WithInsecure())
	assert.NoError(t, err)

	skFT := os.Getenv("TOKEN_ACCOUNT_KEYS")
	address := flow.HexToAddress(os.Getenv("TOKEN_ACCOUNT_ADDRESS"))
	accountFT, err := flowClient.GetAccount(ctx, address)
	assert.NoError(t, err)

	result, err := BurnTokens(ctx, flowClient, accountFT, 50000000000, skFT)
	assert.NoError(t, result.Error)

	balanceFT, err := GetBalance(ctx, flowClient, address)
	assert.NoError(t, err)
	assert.Equal(t, balanceFT.String(), "1000.00000000")
}

func TestCreateNewAdmin(t *testing.T) {
	ctx := context.Background()
	flowClient, err := client.New(os.Getenv("RPC_ADDRESS"), grpc.WithInsecure())
	assert.NoError(t, err)

	skFT := os.Getenv("TOKEN_ACCOUNT_KEYS")
	address := flow.HexToAddress(os.Getenv("TOKEN_ACCOUNT_ADDRESS"))
	accountFT, err := flowClient.GetAccount(ctx, address)
	assert.NoError(t, err)

	skA := "58125e2c18823b7914c625500e76e3006aa2e936bc9b9169f77ab951e84edefd"
	accountA, err := flowClient.GetAccount(ctx, flow.HexToAddress("0x179b6b1cb6755e31"))
	assert.NoError(t, err)

	result, err := CreateAdmin(ctx, flowClient, accountFT, accountA, skFT, skA)
	assert.NoError(t, result.Error)

	// Get the new Sequence Number
	accountA, err = flowClient.GetAccount(ctx, flow.HexToAddress("0x179b6b1cb6755e31"))

	result, err = MintTokens(ctx, flowClient, accountA, 50000000000, skA)
	assert.NoError(t, result.Error)

	balance, err := GetBalance(ctx, flowClient, flow.HexToAddress("0x179b6b1cb6755e31"))
	assert.Equal(t, balance.String(), "500.00000000")

	// Get the new Sequence Number
	accountA, err = flowClient.GetAccount(ctx, flow.HexToAddress("0x179b6b1cb6755e31"))

	result, err = BurnTokens(ctx, flowClient, accountA, 40000000000, skA)
	assert.NoError(t, result.Error)

	balance, err = GetBalance(ctx, flowClient, flow.HexToAddress("0x179b6b1cb6755e31"))
	assert.Equal(t, balance.String(), "100.00000000")
}
