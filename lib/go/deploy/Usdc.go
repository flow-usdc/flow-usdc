package deploy

import (
	"encoding/hex"

	util "github.com/flow-usdc/flow-usdc"
	"github.com/onflow/cadence"

	"github.com/bjartek/go-with-the-flow/gwtf"
)

func DeployUSDCContract(
	g *gwtf.GoWithTheFlow,
	ownerAcct string) (err error) {

	contractCode := util.ParseCadenceTemplate("../../contracts/USDC.cdc")
	txFilename := "../../transactions/deploy_contract_with_auth.cdc"
	code := util.ParseCadenceTemplate(txFilename)
	encodedStr := hex.EncodeToString(contractCode)
	g.CreateAccountPrintEvents("vaulted-account", "non-vaulted-account", "pauser", "non-pauser")
	err = g.TransactionFromFile(txFilename, code).SignProposeAndPayAs(ownerAcct).StringArgument("USDC").StringArgument(encodedStr).RunPrintEventsFull()
	return
}

func GetTotalSupply(g *gwtf.GoWithTheFlow) (result cadence.UFix64, err error) {
	filename := "../../../scripts/get_total_supply.cdc"
	script := util.ParseCadenceTemplate(filename)
	r, err := g.ScriptFromFile(filename, script).RunReturns()
	result = r.(cadence.UFix64)
	return
}
