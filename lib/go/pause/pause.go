package pause

import (
	"github.com/bjartek/go-with-the-flow/gwtf"
	util "github.com/flow-usdc/flow-usdc"
	"github.com/onflow/cadence"
)

func CreatePauser(
	g *gwtf.GoWithTheFlow,
	account string,
) (err error) {
	txFilename := "../../../transactions/pause/create_new_pauser.cdc"
	txScript := util.ParseCadenceTemplate(txFilename)
	err = g.TransactionFromFile(txFilename, txScript).
		SignProposeAndPayAs(account).
		AccountArgument(account).
		RunPrintEventsFull()
	return
}

func SetPauserCapability(
	g *gwtf.GoWithTheFlow,
	pauserAcct string,
	ownerAcct string,
) (err error) {
	txFilename := "../../../transactions/owner/set_pause_cap.cdc"
	txScript := util.ParseCadenceTemplate(txFilename)

	err = g.TransactionFromFile(txFilename, txScript).
		SignProposeAndPayAs(ownerAcct).
		AccountArgument(pauserAcct).
		RunPrintEventsFull()
	return
}

func PauseOrUnpauseContract(
	g *gwtf.GoWithTheFlow,
	pauserAcct string,
	pause uint,
) (err error) {
	var txFilename string

	if pause == 1 {
		txFilename = "../../../transactions/pause/pause_contract.cdc"
	} else {
		txFilename = "../../../transactions/pause/unpause_contract.cdc"
	}

	txScript := util.ParseCadenceTemplate(txFilename)
	err = g.TransactionFromFile(txFilename, txScript).
		SignProposeAndPayAs(pauserAcct).
		RunPrintEventsFull()
	return
}

func GetPaused(g *gwtf.GoWithTheFlow) (cadence.Bool, error) {
	filename := "../../../scripts/get_paused.cdc"
	script := util.ParseCadenceTemplate(filename)
	r, err := g.ScriptFromFile(filename, script).RunReturns()
	paused := r.(cadence.Bool)
	return paused, err
}
