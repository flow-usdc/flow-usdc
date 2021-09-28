package vault

import (
	"github.com/bjartek/go-with-the-flow/v2/gwtf"
	util "github.com/flow-usdc/flow-usdc"
	"github.com/onflow/cadence"
)

func AddVaultToAccount(
	g *gwtf.GoWithTheFlow,
	vaultAcct string,
) (events []*gwtf.FormatedEvent, err error) {
	txFilename := "../../../transactions/vault/create_vault.cdc"
	txScript := util.ParseCadenceTemplate(txFilename)

	MultiSigPubKeys, MultiSigKeyWeights, MultiSigAlgos := util.GetMultiSigKeys(g)
	e, err := g.TransactionFromFile(txFilename, txScript).
		SignProposeAndPayAs(vaultAcct).
		Argument(cadence.NewArray(MultiSigPubKeys)).
		Argument(cadence.NewArray(MultiSigKeyWeights)).
		Argument(cadence.NewArray(MultiSigAlgos)).
		RunE()
	events = util.ParseTestEvents(e)
	return
}

func TransferTokens(
	g *gwtf.GoWithTheFlow,
	amount string,
	fromAcct string,
	toAcct string,
) (events []*gwtf.FormatedEvent, err error) {
	txFilename := "../../../transactions/vault/transfer_FiatToken.cdc"
	txScript := util.ParseCadenceTemplate(txFilename)

	e, err := g.TransactionFromFile(txFilename, txScript).
		SignProposeAndPayAs(fromAcct).
		UFix64Argument(amount).
		AccountArgument(toAcct).
		RunE()
	events = util.ParseTestEvents(e)
	return
}

func MoveAndDeposit(
	g *gwtf.GoWithTheFlow,
	fromAcct string,
	toAcct string,
) (events []*gwtf.FormatedEvent, err error) {
	txFilename := "../../../transactions/vault/move_and_deposit.cdc"
	txScript := util.ParseCadenceTemplate(txFilename)

	e, err := g.TransactionFromFile(txFilename, txScript).
		SignProposeAndPayAs(fromAcct).
		AccountArgument(toAcct).
		RunE()
	events = util.ParseTestEvents(e)
	return
}
