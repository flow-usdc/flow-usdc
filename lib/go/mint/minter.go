package mint

import (
	"errors"

	"github.com/bjartek/go-with-the-flow/gwtf"
	util "github.com/flow-usdc/flow-usdc"
	"github.com/onflow/cadence"
	"github.com/onflow/flow-go-sdk"
)

func CreateMinter(
	g *gwtf.GoWithTheFlow,
	account string,
) (events []flow.Event, err error) {
	txFilename := "../../../transactions/mint/create_new_minter.cdc"
	txScript := util.ParseCadenceTemplate(txFilename)
	events, err = g.TransactionFromFile(txFilename, txScript).
		SignProposeAndPayAs(account).
		AccountArgument(account).
		Run()
	return
}

func GetMinterUUID(g *gwtf.GoWithTheFlow, minterAcct string) (uuid uint64, err error) {
	filename := "../../../scripts/get_minter_uuid.cdc"
	script := util.ParseCadenceTemplate(filename)
	r, err := g.ScriptFromFile(filename, script).AccountArgument(minterAcct).RunReturns()
	uuid, ok := r.ToGoValue().(uint64)
	if !ok {
		err = errors.New("returned not uint64")
	}
	return
}

func GetMinterAllowance(g *gwtf.GoWithTheFlow, minter uint64) (amount cadence.UFix64, err error) {
	filename := "../../../scripts/get_minter_allowance.cdc"
	script := util.ParseCadenceTemplate(filename)
	r, err := g.ScriptFromFile(filename, script).UInt64Argument(minter).RunReturns()
	if err != nil {
		return
	}
	amount = r.(cadence.UFix64)
	return
}

func Mint(g *gwtf.GoWithTheFlow, minterAcct string, amount string, recvAcct string) (events []flow.Event, err error) {
	txFilename := "../../../transactions/mint/mint.cdc"
	txScript := util.ParseCadenceTemplate(txFilename)
	events, err = g.TransactionFromFile(txFilename, txScript).
		SignProposeAndPayAs(minterAcct).
		UFix64Argument(amount).
		AccountArgument(recvAcct).
		Run()
	return
}

func Burn(g *gwtf.GoWithTheFlow, minterAcct string, amount string) (events []flow.Event, err error) {
	txFilename := "../../../transactions/mint/burn.cdc"
	txScript := util.ParseCadenceTemplate(txFilename)
	events, err = g.TransactionFromFile(txFilename, txScript).
		SignProposeAndPayAs(minterAcct).
		UFix64Argument(amount).
		Run()
	return
}
