package blocklist

import (
	"github.com/bjartek/go-with-the-flow/gwtf"
	util "github.com/flow-usdc/flow-usdc"
	"github.com/onflow/cadence"
	"github.com/onflow/flow-go-sdk"
)

func CreateBlocklister(
	g *gwtf.GoWithTheFlow,
	account string,
) (events []flow.Event, err error) {
	txFilename := "../../../transactions/blocklist/create_new_blocklister.cdc"
	txScript := util.ParseCadenceTemplate(txFilename)
	events, err = g.TransactionFromFile(txFilename, txScript).
		SignProposeAndPayAs(account).
		AccountArgument(account).
		Run()
	return
}

func BlocklistOrUnblocklistRsc(
	g *gwtf.GoWithTheFlow,
	blocklisterAcct string,
	rscToBlockOrUnBlock uint64,
	toBlock uint,
) (events []flow.Event, err error) {
	var txFilename string
	if toBlock == 1 {
		txFilename = "../../../transactions/blocklist/blocklist_rsc.cdc"
	} else {
		txFilename = "../../../transactions/blocklist/unblocklist_rsc.cdc"
	}

	txScript := util.ParseCadenceTemplate(txFilename)
	events, err = g.TransactionFromFile(txFilename, txScript).
		UInt64Argument(rscToBlockOrUnBlock).
		SignProposeAndPayAs(blocklisterAcct).
		Run()
	return
}

func GetBlocklistStatus(g *gwtf.GoWithTheFlow, resourceId uint64) (r uint64, err error) {
	filename := "../../../scripts/get_blocklist_status.cdc"
	script := util.ParseCadenceTemplate(filename)
	result, err := g.ScriptFromFile(filename, script).UInt64Argument(resourceId).RunReturns()
	blockHeight := result.(cadence.Optional)
	if blockHeight.ToGoValue() == nil {
		r = 0
	} else {
		r = blockHeight.ToGoValue().(uint64)
	}
	return
}
