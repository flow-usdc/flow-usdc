package pause

import (
	"github.com/bjartek/go-with-the-flow/gwtf"
	util "github.com/flow-usdc/flow-usdc"
	"github.com/onflow/cadence"
)

func CreatePauser(
	g *gwtf.GoWithTheFlow,
	account string,
) (events []*gwtf.FormatedEvent, err error) {
	txFilename := "../../../transactions/pause/create_new_pauser.cdc"
	txScript := util.ParseCadenceTemplate(txFilename)

	MultiSigPubKeys, MultiSigKeyWeights := util.GetMultiSigKeys(g)

	e, err := g.TransactionFromFile(txFilename, txScript).
		SignProposeAndPayAs(account).
		AccountArgument(account).
		Argument(cadence.NewArray(MultiSigPubKeys)).
		Argument(cadence.NewArray(MultiSigKeyWeights)).
		Run()
	events = util.ParseTestEvents(e)
	return
}

func PauseOrUnpauseContract(
	g *gwtf.GoWithTheFlow,
	pauserAcct string,
	pause uint,
) (events []*gwtf.FormatedEvent, err error) {
	var txFilename string

	if pause == 1 {
		txFilename = "../../../transactions/pause/pause_contract.cdc"
	} else {
		txFilename = "../../../transactions/pause/unpause_contract.cdc"
	}

	txScript := util.ParseCadenceTemplate(txFilename)
	e, err := g.TransactionFromFile(txFilename, txScript).
		SignProposeAndPayAs(pauserAcct).
		Run()
	events = util.ParseTestEvents(e)
	return
}

func GetPaused(g *gwtf.GoWithTheFlow) (bool, error) {
	filename := "../../../scripts/contract/get_paused.cdc"
	script := util.ParseCadenceTemplate(filename)
	r, err := g.ScriptFromFile(filename, script).RunReturns()
	paused := r.ToGoValue().(bool)
	return paused, err
}
