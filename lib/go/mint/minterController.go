package mint

import (
	"errors"

	"github.com/bjartek/go-with-the-flow/gwtf"
	util "github.com/flow-usdc/flow-usdc"
)

func CreateMinter(
	g *gwtf.GoWithTheFlow,
	account string,
) (err error) {
	txFilename := "../../../transactions/mint/create_new_minter.cdc"
	txScript := util.ParseCadenceTemplate(txFilename)
	err = g.TransactionFromFile(txFilename, txScript).
		SignProposeAndPayAs(account).
		AccountArgument(account).
		RunPrintEventsFull()
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

// func ConfigureMinter(
// 	g *gwtf.GoWithTheFlow,
// 	minterControllerAcct string,
// 	minter uint64,
// ) (err error) {
// 	txFilename := "../../../transactions/mint/configure_minter.cdc"
// 	txScript := util.ParseCadenceTemplate(txFilename)
// 	err = g.TransactionFromFile(txFilename, txScript).
// 		SignProposeAndPayAs(minterControllerAcct).
// 		UInt64Argument(minter).
// 		RunPrintEventsFull()
// 	return
// }
//
// func GetManagedMinter(g *gwtf.GoWithTheFlow, minterController uint64) (cadence.Bool, error) {
// 	filename := "../../../scripts/get_managed_minter.cdc"
// 	script := util.ParseCadenceTemplate(filename)
//     r, err := g.ScriptFromFile(filename, script).UInt64Argument(minterController).RunReturns()
// 	paused := r.(cadence.Bool)
// 	return paused, err
// }
