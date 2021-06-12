package main

import (
	"context"
	"io/ioutil"

	"github.com/onflow/cadence"
	"github.com/onflow/flow-go-sdk"
	"github.com/onflow/flow-go-sdk/client"
)

func AddVaultToAccount() {
}

func GetSupply(ctx context.Context, flowClient *client.Client) (cadence.UFix64, error) {
	script, err := ioutil.ReadFile("./contracts/scripts/get_supply.cdc")

	value, err := flowClient.ExecuteScriptAtLatestBlock(ctx, script, nil)

	supply := value.(cadence.UFix64)
	return supply, err
}

func GetBalance(ctx context.Context, flowClient *client.Client, address flow.Address) (cadence.UFix64, error) {
	script, err := ioutil.ReadFile("./contracts/scripts/get_balance.cdc")

	value, err := flowClient.ExecuteScriptAtLatestBlock(ctx, script, []cadence.Value{
		cadence.Address(address),
	})

	balance := value.(cadence.UFix64)
	return balance, err
}
