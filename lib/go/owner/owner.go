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

// MultiSig Functions
func MultiSig_ConfigureMinterController(
	g *gwtf.GoWithTheFlow,
	minterController uint64,
	minter uint64,
	txIndex uint64,
	signerAcct string,
	resourceAcct string,
	newPayload bool,
) (events []*gwtf.FormatedEvent, err error) {

	method := "configureMinterController"
	m := cadence.UInt64(minter)
	mc := cadence.UInt64(minterController)
	signable, err := util.GetSignableDataFromScript(g, txIndex, method, m, mc)
	if err != nil {
		return
	}

	sig, err := util.SignPayloadOffline(g, signable, signerAcct)
	if err != nil {
		return
	}

	if newPayload {
		args := []cadence.Value{m, mc}
		return util.MultiSig_NewPayload(g, sig, txIndex, method, args, signerAcct, resourceAcct, "MasterMinter")
	} else {
		return util.MultiSig_AddPayloadSignature(g, sig, txIndex, signerAcct, resourceAcct, "MasterMinter")
	}
}
