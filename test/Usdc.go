package main

import (
	"context"
	"log"

	"github.com/onflow/cadence"
	"github.com/onflow/flow-go-sdk/client"
)

func GetTotalSupply(ctx context.Context, flowClient *client.Client) (cadence.UFix64, error) {
	script := ParseCadenceTemplate("../contracts/scripts/get_usdc_total_supply.cdc")
	log.Println(string(script))

	value, err := flowClient.ExecuteScriptAtLatestBlock(ctx, script, nil)

	supply := value.(cadence.UFix64)
	return supply, err
}
