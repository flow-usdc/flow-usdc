package vault

import (
	"github.com/bjartek/go-with-the-flow/gwtf"
	util "github.com/flow-usdc/flow-usdc"
	"github.com/onflow/flow-go-sdk"
)

func AddVaultToAccount(
	g *gwtf.GoWithTheFlow,
	vaultAcct string,
) (events []flow.Event, err error) {
	txFilename := "../../../transactions/create_vault.cdc"
	txScript := util.ParseCadenceTemplate(txFilename)
	events, err = g.TransactionFromFile(txFilename, txScript).
		SignProposeAndPayAs(vaultAcct).
		Run()
	return
}

func TransferTokens(
	g *gwtf.GoWithTheFlow,
	amount string,
	fromAcct string,
	toAcct string,
) (events []flow.Event, err error) {
	txFilename := "../../../transactions/transfer_FiatToken.cdc"
	txScript := util.ParseCadenceTemplate(txFilename)

	events, err = g.TransactionFromFile(txFilename, txScript).
		SignProposeAndPayAs(fromAcct).
		UFix64Argument(amount).
		AccountArgument(toAcct).
		Run()
	return
}
