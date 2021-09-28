package mint

import (
	"os"
	"strconv"
	"testing"

	"github.com/bjartek/go-with-the-flow/v2/gwtf"
	util "github.com/flow-usdc/flow-usdc"
	"github.com/stretchr/testify/assert"
)

func TestMasterMinterMultiSig_ConfigureMC(t *testing.T) {
	g := gwtf.NewGoWithTheFlow(util.FlowJSON, os.Getenv("NETWORK"), false, 1)

	// Add New Payload
	currentIndex, err := util.GetTxIndex(g, "owner", "MasterMinter")
	assert.NoError(t, err)
	expectedNewIndex := currentIndex + 1

	minterController := uint64(222)
	minter := uint64(111)
	m := util.Arg{V: minter, T: "UInt64"}
	mc := util.Arg{V: minterController, T: "UInt64"}
	// `true` for new payload
	events, err := util.MultiSig_SignAndSubmit(g, true, expectedNewIndex, util.Acct500_1, "owner", "MasterMinter", "configureMinterController", m, mc)
	assert.NoError(t, err)

	newTxIndex, err := util.GetTxIndex(g, "owner", "MasterMinter")
	assert.NoError(t, err)
	assert.Equal(t, expectedNewIndex, newTxIndex)

	masterMinter, err := util.GetUUID(g, "owner", "MasterMinter")
	assert.NoError(t, err)

	util.NewExpectedEvent("OnChainMultiSig", "NewPayloadAdded").
		AddField("resourceId", strconv.Itoa(int(masterMinter))).
		AddField("txIndex", strconv.Itoa(int(newTxIndex))).
		AssertEqual(t, events[0])

		// Try to Execute without enough weight. This should error as there is not enough signer yet
	_, err = util.MultiSig_ExecuteTx(g, newTxIndex, "owner", "owner", "MasterMinter")
	assert.Error(t, err)

	// Add Another Payload Signature
	// `false` for new signature for existing paylaod
	events, err = util.MultiSig_SignAndSubmit(g, false, newTxIndex, util.Acct500_2, "owner", "MasterMinter", "configureMinterController", m, mc)
	assert.NoError(t, err)

	util.NewExpectedEvent("OnChainMultiSig", "NewPayloadSigAdded").
		AddField("resourceId", strconv.Itoa(int(masterMinter))).
		AddField("txIndex", strconv.Itoa(int(newTxIndex))).
		AssertEqual(t, events[0])

		// Try to Execute Tx after second signature
	events, err = util.MultiSig_ExecuteTx(g, newTxIndex, "owner", "owner", "MasterMinter")
	assert.NoError(t, err)
	util.NewExpectedEvent("FiatToken", "ControllerConfigured").
		AddField("controller", strconv.Itoa(int(minterController))).
		AddField("minter", strconv.Itoa(int(minter))).
		AssertEqual(t, events[0])
	managedMinter, err := GetManagedMinter(g, minterController)
	assert.NoError(t, err)
	assert.Equal(t, minter, managedMinter)
}

func TestMasterMinterMultiSig_RemoveMC(t *testing.T) {
	g := gwtf.NewGoWithTheFlow(util.FlowJSON, os.Getenv("NETWORK"), false, 1)

	// Add New Payload
	currentIndex, err := util.GetTxIndex(g, "owner", "MasterMinter")
	assert.NoError(t, err)
	expectedNewIndex := currentIndex + 1

	minterController := uint64(222)
	mc := util.Arg{V: minterController, T: "UInt64"}
	// `true` for new payload
	events, err := util.MultiSig_SignAndSubmit(g, true, expectedNewIndex, util.Acct1000, "owner", "MasterMinter", "removeMinterController", mc)
	assert.NoError(t, err)

	newTxIndex, err := util.GetTxIndex(g, "owner", "MasterMinter")
	assert.NoError(t, err)
	assert.Equal(t, expectedNewIndex, newTxIndex)

	masterMinter, err := util.GetUUID(g, "owner", "MasterMinter")
	assert.NoError(t, err)

	util.NewExpectedEvent("OnChainMultiSig", "NewPayloadAdded").
		AddField("resourceId", strconv.Itoa(int(masterMinter))).
		AddField("txIndex", strconv.Itoa(int(newTxIndex))).
		AssertEqual(t, events[0])

	events, err = util.MultiSig_ExecuteTx(g, newTxIndex, "owner", "owner", "MasterMinter")
	assert.NoError(t, err)
	util.NewExpectedEvent("FiatToken", "ControllerRemoved").
		AddField("controller", strconv.Itoa(int(minterController))).
		AssertEqual(t, events[0])

	_, err = GetManagedMinter(g, minterController)
	assert.Error(t, err)
}

func TestMasterMinterMultiSig_UnknowMethodFails(t *testing.T) {
	g := gwtf.NewGoWithTheFlow(util.FlowJSON, os.Getenv("NETWORK"), false, 1)
	mc := util.Arg{V: uint64(222), T: "UInt64"}
	m := util.Arg{V: uint64(111), T: "UInt64"}

	txIndex, err := util.GetTxIndex(g, "owner", "MasterMinter")
	assert.NoError(t, err)

	_, err = util.MultiSig_SignAndSubmit(g, true, txIndex+1, util.Acct1000, "owner", "MasterMinter", "configureUKNOWMETHODController", m, mc)
	assert.NoError(t, err)

	newTxIndex, err := util.GetTxIndex(g, "owner", "MasterMinter")
	assert.NoError(t, err)

	_, err = util.MultiSig_ExecuteTx(g, newTxIndex, "owner", "owner", "MasterMinter")
	assert.Error(t, err)
}

func TestMasterMinterMultiSig_CanRemoveKey(t *testing.T) {
	g := gwtf.NewGoWithTheFlow(util.FlowJSON, os.Getenv("NETWORK"), false, 1)
	pk250_1 := g.Account(util.Acct250_1).Key().ToConfig().PrivateKey.PublicKey().String()
	k := util.Arg{V: pk250_1[2:], T: "String"}

	hasKey, err := util.ContainsKey(g, "owner", "MasterMinter", pk250_1[2:])
	assert.NoError(t, err)
	assert.Equal(t, hasKey, true)

	txIndex, err := util.GetTxIndex(g, "owner", "MasterMinter")
	newTxIndex := txIndex + 1
	assert.NoError(t, err)

	_, err = util.MultiSig_SignAndSubmit(g, true, newTxIndex, util.Acct1000, "owner", "MasterMinter", "removeKey", k)
	assert.NoError(t, err)

	_, err = util.MultiSig_ExecuteTx(g, newTxIndex, "owner", "owner", "MasterMinter")
	assert.NoError(t, err)

	hasKey, err = util.ContainsKey(g, "owner", "MasterMinter", pk250_1[2:])
	assert.NoError(t, err)
	assert.Equal(t, hasKey, false)
}

func TestMasterMinterMultiSig_CanAddKey(t *testing.T) {
	g := gwtf.NewGoWithTheFlow(util.FlowJSON, os.Getenv("NETWORK"), false, 1)
	pk250_1 := g.Account(util.Acct250_1).Key().ToConfig().PrivateKey.PublicKey().String()

	k := util.Arg{V: pk250_1[2:], T: "String"}
	w := util.Arg{V: "250.00000000", T: "UFix64"}
	sa := util.Arg{V: uint8(1), T: "UInt8"}

	hasKey, err := util.ContainsKey(g, "owner", "MasterMinter", pk250_1[2:])
	assert.NoError(t, err)
	assert.Equal(t, hasKey, false)

	txIndex, err := util.GetTxIndex(g, "owner", "MasterMinter")
	newTxIndex := txIndex + 1
	assert.NoError(t, err)

	_, err = util.MultiSig_SignAndSubmit(g, true, newTxIndex, util.Acct1000, "owner", "MasterMinter", "configureKey", k, w, sa)
	assert.NoError(t, err)

	_, err = util.MultiSig_ExecuteTx(g, newTxIndex, "owner", "owner", "MasterMinter")
	assert.NoError(t, err)

	hasKey, err = util.ContainsKey(g, "owner", "MasterMinter", pk250_1[2:])
	assert.NoError(t, err)
	assert.Equal(t, hasKey, true)

	weight, err := util.GetKeyWeight(g, util.Acct250_1, "owner", "MasterMinter")
	assert.NoError(t, err)
	assert.Equal(t, w.V, weight.String())
}
