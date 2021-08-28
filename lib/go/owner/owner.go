package owner

import (
	"github.com/bjartek/go-with-the-flow/v2/gwtf"
	util "github.com/flow-usdc/flow-usdc"
)

// Uses the Pause Executor Resource Capabilities
func SetPauserCapability(
	g *gwtf.GoWithTheFlow,
	pauserAcct string,
	ownerAcct string,
) (err error) {
	txFilename := "../../../transactions/owner/set_pause_cap.cdc"
	txScript := util.ParseCadenceTemplate(txFilename)

	_, err = g.TransactionFromFile(txFilename, txScript).
		SignProposeAndPayAs(ownerAcct).
		AccountArgument(pauserAcct).
		RunE()
	return
}

// Uses the Blocklist Executor Resource Capabilities
func SetBlocklistCapability(
	g *gwtf.GoWithTheFlow,
	blocklisterAcct string,
	ownerAcct string,
) (err error) {
	txFilename := "../../../transactions/owner/set_blocklist_cap.cdc"
	txScript := util.ParseCadenceTemplate(txFilename)

	_, err = g.TransactionFromFile(txFilename, txScript).
		SignProposeAndPayAs(ownerAcct).
		AccountArgument(blocklisterAcct).
		RunE()
	return
}

// Uses the MasterMinter Resource Capabilities
func ConfigureMinterController(
	g *gwtf.GoWithTheFlow,
	minterController uint64,
	minter uint64,
	ownerAcct string,
) (events []*gwtf.FormatedEvent, err error) {
	txFilename := "../../../transactions/owner/configure_minter_controller.cdc"
	txScript := util.ParseCadenceTemplate(txFilename)

	e, err := g.TransactionFromFile(txFilename, txScript).
		SignProposeAndPayAs(ownerAcct).
		UInt64Argument(minter).
		UInt64Argument(minterController).
		RunE()
	events = util.ParseTestEvents(e)
	return
}

// Uses the MasterMinter Resource Capabilities
func RemoveMinterController(
	g *gwtf.GoWithTheFlow,
	minterController uint64,
	ownerAcct string,
) (events []*gwtf.FormatedEvent, err error) {
	txFilename := "../../../transactions/owner/remove_minter_controller.cdc"
	txScript := util.ParseCadenceTemplate(txFilename)

	e, err := g.TransactionFromFile(txFilename, txScript).
		SignProposeAndPayAs(ownerAcct).
		UInt64Argument(minterController).
		RunE()
	events = util.ParseTestEvents(e)
	return
}
