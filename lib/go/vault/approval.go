package vault

import (
	"github.com/bjartek/go-with-the-flow/gwtf"
	util "github.com/flow-usdc/flow-usdc"
	"github.com/onflow/cadence"
)

func Approve(
	g *gwtf.GoWithTheFlow,
	fromAcct string,
	toResourceId uint64,
	amount string,
) (events []*gwtf.FormatedEvent, err error) {
	txFilename := "../../../transactions/vault/approval.cdc"
	txScript := util.ParseCadenceTemplate(txFilename)
	e, err := g.TransactionFromFile(txFilename, txScript).
		SignProposeAndPayAs(fromAcct).
		UInt64Argument(toResourceId).
		UFix64Argument(amount).
		Run()
	events = util.ParseTestEvents(e)
	return
}

func GetAllowance(
	g *gwtf.GoWithTheFlow,
	fromAcct string,
	toResourceId uint64,
) (result cadence.UFix64, err error) {
	filename := "../../../scripts/vault/get_allowance.cdc"
	script := util.ParseCadenceTemplate(filename)
	r, err := g.ScriptFromFile(filename, script).
		AccountArgument(fromAcct).
		UInt64Argument(toResourceId).
		RunReturns()
	if err != nil {
		return
	}
	result = r.(cadence.UFix64)
	return
}

func WithdrawAllowance(
	g *gwtf.GoWithTheFlow,
	signAcct string,
	fromAcct string,
	toAcct string,
	amount string,
) (events []*gwtf.FormatedEvent, err error) {
	txFilename := "../../../transactions/vault/withdraw_allowance.cdc"
	txScript := util.ParseCadenceTemplate(txFilename)
	e, err := g.TransactionFromFile(txFilename, txScript).
		SignProposeAndPayAs(signAcct).
		AccountArgument(fromAcct).
		AccountArgument(toAcct).
		UFix64Argument(amount).
		Run()
	events = util.ParseTestEvents(e)
	return
}

func IncreaseOrDecreaseAlowance(
	g *gwtf.GoWithTheFlow,
	fromAcct string,
	toResourceId uint64,
	absDelta string,
	inc uint,
) (events []*gwtf.FormatedEvent, err error) {
	var txFilename string

	if inc == 1 {
		txFilename = "../../../transactions/vault/increaseAllowance.cdc"
	} else {
		txFilename = "../../../transactions/vault/decreaseAllowance.cdc"
	}

	txScript := util.ParseCadenceTemplate(txFilename)
	e, err := g.TransactionFromFile(txFilename, txScript).
		SignProposeAndPayAs(fromAcct).
		UInt64Argument(toResourceId).
		UFix64Argument(absDelta).
		Run()
	events = util.ParseTestEvents(e)
	return
}
