package mint

import (
	"github.com/bjartek/go-with-the-flow/v2/gwtf"
	util "github.com/flow-usdc/flow-usdc"
	"github.com/onflow/cadence"
)

func CreateMinter(
	g *gwtf.GoWithTheFlow,
	account string,
) (events []*gwtf.FormatedEvent, err error) {
	txFilename := "../../../transactions/mint/create_new_minter.cdc"
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

func GetMinterAllowance(g *gwtf.GoWithTheFlow, minter uint64) (amount cadence.UFix64, err error) {
	filename := "../../../scripts/contract/get_minter_allowance.cdc"
	script := util.ParseCadenceTemplate(filename)
	r, err := g.ScriptFromFile(filename, script).UInt64Argument(minter).RunReturns()
	if err != nil {
		return
	}
	amount = r.(cadence.UFix64)
	return
}

func Mint(g *gwtf.GoWithTheFlow, minterAcct string, amount string, recvAcct string) (events []*gwtf.FormatedEvent, err error) {
	txFilename := "../../../transactions/mint/mint.cdc"
	txScript := util.ParseCadenceTemplate(txFilename)
	e, err := g.TransactionFromFile(txFilename, txScript).
		SignProposeAndPayAs(minterAcct).
		UFix64Argument(amount).
		AccountArgument(recvAcct).
		RunE()
	events = util.ParseTestEvents(e)
	return
}

func Burn(g *gwtf.GoWithTheFlow, minterAcct string, amount string) (events []*gwtf.FormatedEvent, err error) {
	txFilename := "../../../transactions/mint/burn.cdc"
	txScript := util.ParseCadenceTemplate(txFilename)
	e, err := g.TransactionFromFile(txFilename, txScript).
		SignProposeAndPayAs(minterAcct).
		UFix64Argument(amount).
		RunE()
	events = util.ParseTestEvents(e)
	return
}
