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
// Uses the MasterMinter Resource Capabilities
func MultiSig_ConfigureMinterController(
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

func MultiSig_VaultAddPayloadSignature(
	g *gwtf.GoWithTheFlow,
	sig string,
	txIndex uint64,
	signerAcct string,
	resourceAcct string,
) (events []*gwtf.FormatedEvent, err error) {
	txFilename := "../../../transactions/add_payload_signature.cdc"
	txScript := util.ParseCadenceTemplate(txFilename)

	signerPubKey := g.Accounts[signerAcct].PrivateKey.PublicKey().String()
	e, err := g.TransactionFromFile(txFilename, txScript).
		SignProposeAndPayAs(signerAcct).
		StringArgument(sig).
		UInt64Argument(txIndex).
		StringArgument(signerPubKey[2:]).
		AccountArgument(resourceAcct).
		Run()
	events = util.ParseTestEvents(e)
	return
}

func MultiSig_MasterMinterExecuteTx(
	g *gwtf.GoWithTheFlow,
	index uint64,
	payerAcct string,
	vaultAcct string,
) (events []*gwtf.FormatedEvent, err error) {
	txFilename := "../../../transactions/owner/masterMinterExecuteTx.cdc"
	txScript := util.ParseCadenceTemplate(txFilename)

	e, err := g.TransactionFromFile(txFilename, txScript).
		SignProposeAndPayAs(payerAcct).
		AccountArgument(vaultAcct).
		UInt64Argument(index).
		Run()
	events = util.ParseTestEvents(e)
	return
}

