package deploy

import (
	"context"
	"encoding/hex"

	util "github.com/flow-usdc/flow-usdc"
	"github.com/onflow/cadence"
	"github.com/onflow/flow-go-sdk/client"

	//	"github.com/onflow/flow-go-sdk/crypto"
	"github.com/bjartek/go-with-the-flow/gwtf"
)

func DeployUSDCContract(
	ctx context.Context,
	flowClient *client.Client,
	ownerAcctAddr string,
	skString string) {
	g := gwtf.
		NewGoWithTheFlow("/Users/belsy/flow/flow-usdc/flow.json")
	code := util.ParseCadenceTemplate("../../contracts/USDC.cdc")
	encodedStr := hex.EncodeToString(code)
	g.TransactionFromFile("../../transactions/deploy_contract_with_auth.cdc").SignProposeAndPayAs("token-account").StringArgument("USDC").StringArgument(encodedStr).RunPrintEventsFull()
}

func GetTotalSupply(ctx context.Context, flowClient *client.Client) (cadence.UFix64, error) {
	script := util.ParseCadenceTemplate("../../../scripts/get_total_supply.cdc")
	value, err := flowClient.ExecuteScriptAtLatestBlock(ctx, script, nil)
	supply := value.(cadence.UFix64)
	return supply, err
}
