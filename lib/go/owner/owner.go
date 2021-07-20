package owner

import (
	"github.com/bjartek/go-with-the-flow/gwtf"
	util "github.com/flow-usdc/flow-usdc"
	"github.com/onflow/cadence"
)

// Uses the Pause Executor Resource Capabilities
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

// Uses the Blocklist Executor Resource Capabilities
func SetBlocklistCapability(
	g *gwtf.GoWithTheFlow,
	blocklisterAcct string,
	ownerAcct string,
) (err error) {
	txFilename := "../../../transactions/owner/set_blocklist_cap.cdc"
	txScript := util.ParseCadenceTemplate(txFilename)

	err = g.TransactionFromFile(txFilename, txScript).
		SignProposeAndPayAs(ownerAcct).
		AccountArgument(blocklisterAcct).
		RunPrintEventsFull()
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
		Run()
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
		Run()
	events = util.ParseTestEvents(e)
	return
}

// Uses the MasterMinter Resource Capabilities
func MultiSig_NewConfigureMinterController(
	g *gwtf.GoWithTheFlow,
	minterController uint64,
	minter uint64,
	keyListIndex int,
	ownerAcct string,
) (events []*gwtf.FormatedEvent, err error) {
	txFilename := "../../../transactions/owner/multisig/new_configure_minter_controller.cdc"
	txScript := util.ParseCadenceTemplate(txFilename)

	signable, err := util.GetSignableDataFromScript(g, "configureMinterController", uint64(123), uint64(345))
	if err != nil {
		return
	}

	sig, err := util.SignPayloadOffline(g, signable, "owner")
	if err != nil {
		return
	}

	var sigArray []cadence.Value
	for e := range sig {
		sigArray = append(sigArray, cadence.UInt8(e))
	}

	e, err := g.TransactionFromFile(txFilename, txScript).
		SignProposeAndPayAs(ownerAcct).
		IntArgument(keyListIndex).
		Argument(cadence.NewArray(sigArray)).
		AccountArgument("owner").
		StringArgument("configureMinterController").
		UInt64Argument(minter).
		UInt64Argument(minterController).
		Run()
	events = util.ParseTestEvents(e)
	return
}

func MultiSig_MasterMinterExecuteTx(
	g *gwtf.GoWithTheFlow,
	index uint64,
	ownerAcct string,
) (events []*gwtf.FormatedEvent, err error) {
	txFilename := "../../../transactions/owner/multisig/executeTx.cdc"
	txScript := util.ParseCadenceTemplate(txFilename)

	e, err := g.TransactionFromFile(txFilename, txScript).
		SignProposeAndPayAs(ownerAcct).
		AccountArgument("owner").
		UInt64Argument(index).
		Run()
	events = util.ParseTestEvents(e)
	return

}
