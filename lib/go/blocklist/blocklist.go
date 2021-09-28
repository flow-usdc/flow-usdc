package blocklist

import (
	"github.com/bjartek/go-with-the-flow/v2/gwtf"
	util "github.com/flow-usdc/flow-usdc"
	"github.com/onflow/cadence"
)

func CreateBlocklister(
	g *gwtf.GoWithTheFlow,
	account string,
) (events []*gwtf.FormatedEvent, err error) {
	txFilename := "../../../transactions/blocklist/create_new_blocklister.cdc"
	txScript := util.ParseCadenceTemplate(txFilename)

	MultiSigPubKeys, MultiSigKeyWeights, MultiSigAlgos := util.GetMultiSigKeys(g)

	e, err := g.TransactionFromFile(txFilename, txScript).
		SignProposeAndPayAs(account).
		AccountArgument(account).
		Argument(cadence.NewArray(MultiSigPubKeys)).
		Argument(cadence.NewArray(MultiSigKeyWeights)).
		Argument(cadence.NewArray(MultiSigAlgos)).
		RunE()
	events = util.ParseTestEvents(e)
	return
}

func BlocklistOrUnblocklistRsc(
	g *gwtf.GoWithTheFlow,
	blocklisterAcct string,
	rscToBlockOrUnBlock uint64,
	toBlock uint,
) (events []*gwtf.FormatedEvent, err error) {
	var txFilename string
	if toBlock == 1 {
		txFilename = "../../../transactions/blocklist/blocklist_rsc.cdc"
	} else {
		txFilename = "../../../transactions/blocklist/unblocklist_rsc.cdc"
	}

	txScript := util.ParseCadenceTemplate(txFilename)
	e, err := g.TransactionFromFile(txFilename, txScript).
		UInt64Argument(rscToBlockOrUnBlock).
		SignProposeAndPayAs(blocklisterAcct).
		RunE()
	events = util.ParseTestEvents(e)
	return
}

func GetBlocklistStatus(g *gwtf.GoWithTheFlow, resourceId uint64) (r uint64, err error) {
	filename := "../../../scripts/contract/get_blocklist_status.cdc"
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
