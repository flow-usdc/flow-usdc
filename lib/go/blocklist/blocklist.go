package blocklist

import (
	"github.com/bjartek/go-with-the-flow/gwtf"
	util "github.com/flow-usdc/flow-usdc"
	"github.com/onflow/cadence"
)

func CreateBlocklister(
	g *gwtf.GoWithTheFlow,
	account string,
) (err error) {
	txFilename := "../../../transactions/blocklist/create_new_blocklister.cdc"
	txScript := util.ParseCadenceTemplate(txFilename)
	err = g.TransactionFromFile(txFilename, txScript).
		SignProposeAndPayAs(account).
		AccountArgument(account).
		RunPrintEventsFull()
	return
}

func SetBlocklistCapability(
	g *gwtf.GoWithTheFlow,
	blocklisterAcct string,
	ownerAcct string,
) (err error) {
	txFilename := "../../../transactions/owner/set_blocklist_cap.cdc"
	txScript := util.ParseCadenceTemplate(txFilename)

	err = g.TransactionFromFile(txFilename, txScript).
		SignProposeAndPayAs(ownerAcct).
		AccountArgument(blocklisterAcct).
		RunPrintEventsFull()
	return
}

func BlocklistOrUnblocklistRsc(
	g *gwtf.GoWithTheFlow,
	blocklisterAcct string,
	rscToBlockOrUnBlock uint64,
	toBlock uint,
) (err error) {
	var txFilename string
	if toBlock == 1 {
		txFilename = "../../../transactions/blocklist/blocklist_rsc.cdc"
	} else {
		txFilename = "../../../transactions/blocklist/unblocklist_rsc.cdc"
	}

	txScript := util.ParseCadenceTemplate(txFilename)
	err = g.TransactionFromFile(txFilename, txScript).
		UInt64Argument(rscToBlockOrUnBlock).
		SignProposeAndPayAs(blocklisterAcct).
		RunPrintEventsFull()
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
