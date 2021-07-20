package pause

import (
	"github.com/bjartek/go-with-the-flow/gwtf"
	util "github.com/flow-usdc/flow-usdc"
	"github.com/onflow/cadence"
	"github.com/onflow/flow-go-sdk"
)

func CreatePauser(
	g *gwtf.GoWithTheFlow,
	account string,
) (events []flow.Event, err error) {
	txFilename := "../../../transactions/pause/create_new_pauser.cdc"
	txScript := util.ParseCadenceTemplate(txFilename)
	events, err = g.TransactionFromFile(txFilename, txScript).
		SignProposeAndPayAs(account).
		AccountArgument(account).
		Run()
	return
}

func PauseOrUnpauseContract(
	g *gwtf.GoWithTheFlow,
	pauserAcct string,
	pause uint,
) (events []flow.Event, err error) {
	var txFilename string

	if pause == 1 {
		txFilename = "../../../transactions/pause/pause_contract.cdc"
	} else {
		txFilename = "../../../transactions/pause/unpause_contract.cdc"
	}

	txScript := util.ParseCadenceTemplate(txFilename)
	events, err = g.TransactionFromFile(txFilename, txScript).
		SignProposeAndPayAs(pauserAcct).
		Run()
	return
}

func GetPaused(g *gwtf.GoWithTheFlow) (cadence.Bool, error) {
	filename := "../../../scripts/get_paused.cdc"
	script := util.ParseCadenceTemplate(filename)
	r, err := g.ScriptFromFile(filename, script).RunReturns()
	paused := r.(cadence.Bool)
	return paused, err
}
