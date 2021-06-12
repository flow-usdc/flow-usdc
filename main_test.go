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
}

func TestGetSupply(t *testing.T) {
	ctx := context.Background()
	flowClient, err := client.New("localhost:3569", grpc.WithInsecure())
	assert.NoError(t, err)

	supply, err := GetSupply(ctx, flowClient)
	assert.Equal(t, supply.String(), "1000.00000000")
}

func TestGetBalance(t *testing.T) {
	ctx := context.Background()
	flowClient, err := client.New("localhost:3569", grpc.WithInsecure())
	assert.NoError(t, err)

	balance, err := GetBalance(ctx, flowClient, flow.HexToAddress("0x01cf0e2f2f715450"))

	assert.Equal(t, balance.String(), "1000.00000000")
}

func TestAddVaultToAccount(t *testing.T) {
	ctx := context.Background()
	flowClient, err := client.New("localhost:3569", grpc.WithInsecure())
	assert.NoError(t, err)

	txScript, err := ioutil.ReadFile("./transactions/setup_account.cdc")
	assert.NoError(t, err)

	accountA, err := flowClient.GetAccount(ctx, flow.HexToAddress("0x179b6b1cb6755e31"))
	assert.NoError(t, err)

	key1 := accountA.Keys[0]

	privateKey, err := crypto.DecodePrivateKeyHex(crypto.ECDSA_P256, "58125e2c18823b7914c625500e76e3006aa2e936bc9b9169f77ab951e84edefd")
	assert.NoError(t, err)
	key1Signer := crypto.NewInMemorySigner(privateKey, key1.HashAlgo)

	referenceBlock, err := flowClient.GetLatestBlock(ctx, true)
	assert.NoError(t, err)

	tx := flow.NewTransaction().
		SetScript(txScript).
		SetGasLimit(100).
		SetProposalKey(accountA.Address, key1.Index, key1.SequenceNumber).
		SetPayer(accountA.Address).
		SetReferenceBlockID(referenceBlock.ID).
		AddAuthorizer(accountA.Address)

	err = tx.SignEnvelope(accountA.Address, key1.Index, key1Signer)
	assert.NoError(t, err)

	err = flowClient.SendTransaction(ctx, *tx)
	assert.NoError(t, err)

	balance, err := GetBalance(ctx, flowClient, accountA.Address)

	assert.Equal(t, balance.String(), "0.00000000")
}

func TestNonVaultedAccount(t *testing.T) {
	ctx := context.Background()
	flowClient, err := client.New("localhost:3569", grpc.WithInsecure())
	assert.NoError(t, err)

	accountB, err := flowClient.GetAccount(ctx, flow.HexToAddress("0xf3fcd2c1a78f5eee"))
	assert.NoError(t, err)

	script, err := ioutil.ReadFile("./contracts/scripts/get_balance.cdc")
	assert.NoError(t, err)

	_, err = flowClient.ExecuteScriptAtLatestBlock(ctx, script, []cadence.Value{
		cadence.Address(accountB.Address),
	})
	assert.Error(t, err)
}

func TestTransferAndTransferBack(t *testing.T) {
	ctx := context.Background()
	flowClient, err := client.New("localhost:3569", grpc.WithInsecure())
	assert.NoError(t, err)

	accountFT, err := flowClient.GetAccount(ctx, flow.HexToAddress("0x01cf0e2f2f715450"))
	assert.NoError(t, err)

	accountA, err := flowClient.GetAccount(ctx, flow.HexToAddress("0x179b6b1cb6755e31"))
	assert.NoError(t, err)

	key1 := accountFT.Keys[0]

	privateKey, err := crypto.DecodePrivateKeyHex(crypto.ECDSA_P256, "5eb8df48667ac74981f4faaf8b425a6403c8729e90319a4cbfd7942b10e4622a")
	assert.NoError(t, err)
	key1Signer := crypto.NewInMemorySigner(privateKey, key1.HashAlgo)

	txScript, err := ioutil.ReadFile("./contracts/scripts/transfer_tokens.cdc")

	referenceBlock, err := flowClient.GetLatestBlock(ctx, true)
	assert.NoError(t, err)

	tx := flow.NewTransaction().
		SetScript(txScript).
		SetGasLimit(100).
		SetProposalKey(accountFT.Address, key1.Index, key1.SequenceNumber).
		SetPayer(accountFT.Address).
		SetReferenceBlockID(referenceBlock.ID).
		AddAuthorizer(accountFT.Address)

	err = tx.AddArgument(cadence.UFix64(10.0))
	assert.NoError(t, err)

	err = tx.AddArgument(cadence.Address(accountA.Address))
	assert.NoError(t, err)

	err = tx.SignEnvelope(accountFT.Address, key1.Index, key1Signer)
	assert.NoError(t, err)

	//  Transfer from Account A to Account B
	//  flow transactions send ./transactions/transfer_tokens.cdc \
	//    --arg UFix64:500.0 \
	//    --arg Address:0x"$ACCOUNT_B" \
	//    --signer=ft-account
	//
	//  flow scripts execute ./contracts/scripts/get_balance.cdc --arg Address:0x"$ACCOUNT_B"
	//
	//  Transfer from Account B back to Account A
	//  flow transactions send ./transactions/transfer_tokens.cdc \
	//    --arg UFix64:50.0 \
	//    --arg Address:0x"$ACCOUNT_A" \
	//    --signer=receiver-account
	//
	//  flow scripts execute ./contracts/scripts/get_balance.cdc --arg Address:0x"$ACCOUNT_A"
}
