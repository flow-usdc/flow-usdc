package mint

import (
	"errors"

	"github.com/bjartek/go-with-the-flow/v2/gwtf"
	util "github.com/flow-usdc/flow-usdc"
	"github.com/onflow/cadence"
)

func CreateMinterController(
	g *gwtf.GoWithTheFlow,
	account string,
) (events []*gwtf.FormatedEvent, err error) {
	txFilename := "../../../transactions/minterControl/create_new_minter_controller.cdc"
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

func GetManagedMinter(g *gwtf.GoWithTheFlow, minterController uint64) (uuid uint64, err error) {
	filename := "../../../scripts/contract/get_managed_minter.cdc"
	script := util.ParseCadenceTemplate(filename)
	r, err := g.ScriptFromFile(filename, script).UInt64Argument(minterController).RunReturns()
	uuid, ok := r.ToGoValue().(uint64)
	if !ok {
		err = errors.New("returned nil")
	}
	return
}

func ConfigureMinterAllowance(
	g *gwtf.GoWithTheFlow,
	minterControllerAcct string,
	amount string,
) (events []*gwtf.FormatedEvent, err error) {
	txFilename := "../../../transactions/minterControl/configure_minter_allowance.cdc"
	txScript := util.ParseCadenceTemplate(txFilename)
	e, err := g.TransactionFromFile(txFilename, txScript).
		SignProposeAndPayAs(minterControllerAcct).
		UFix64Argument(amount).
		RunE()
	events = util.ParseTestEvents(e)
	return
}

func RemoveMinter(
	g *gwtf.GoWithTheFlow,
	minterControllerAcct string,
) (events []*gwtf.FormatedEvent, err error) {
	txFilename := "../../../transactions/minterControl/remove_minter.cdc"
	txScript := util.ParseCadenceTemplate(txFilename)
	e, err := g.TransactionFromFile(txFilename, txScript).
		SignProposeAndPayAs(minterControllerAcct).
		RunE()
	events = util.ParseTestEvents(e)
	return
}

func IncreaseOrDecreaseMinterAllowance(
	g *gwtf.GoWithTheFlow,
	minterControllerAcct string,
	absDelta string,
	inc uint,
) (events []*gwtf.FormatedEvent, err error) {
	var txFilename string
	if inc == 1 {
		txFilename = "../../../transactions/minterControl/increase_minter_allowance.cdc"
	} else {
		txFilename = "../../../transactions/minterControl/decrease_minter_allowance.cdc"
	}

	txScript := util.ParseCadenceTemplate(txFilename)
	e, err := g.TransactionFromFile(txFilename, txScript).
		SignProposeAndPayAs(minterControllerAcct).
		UFix64Argument(absDelta).
		RunE()
	events = util.ParseTestEvents(e)
	return
}
