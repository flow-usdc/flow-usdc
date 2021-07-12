package mint

import (
	"errors"

	"github.com/bjartek/go-with-the-flow/gwtf"
	util "github.com/flow-usdc/flow-usdc"
)

func CreateMinterController(
	g *gwtf.GoWithTheFlow,
	account string,
) (err error) {
	txFilename := "../../../transactions/mint/create_new_minter_controller.cdc"
	txScript := util.ParseCadenceTemplate(txFilename)
	err = g.TransactionFromFile(txFilename, txScript).
		SignProposeAndPayAs(account).
		AccountArgument(account).
		RunPrintEventsFull()
	return
}

func GetMinterControllerUUID (g *gwtf.GoWithTheFlow, minterControllerAcct string) (uuid uint64,err error) {
	filename := "../../../scripts/get_minter_controller_uuid.cdc"
	script := util.ParseCadenceTemplate(filename)
    r, err := g.ScriptFromFile(filename, script).AccountArgument(minterControllerAcct).RunReturns()
	uuid, ok := r.ToGoValue().(uint64)
	if !ok {
		err = errors.New("returned not uint64")
	}
	return
}
