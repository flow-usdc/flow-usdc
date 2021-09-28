package mint

import (
	"os"
	"strconv"
	"testing"

	"github.com/bjartek/go-with-the-flow/v2/gwtf"
	util "github.com/flow-usdc/flow-usdc"
	"github.com/flow-usdc/flow-usdc/owner"
	"github.com/onflow/cadence"
	"github.com/stretchr/testify/assert"
)

func TestController_Create(t *testing.T) {
	g := gwtf.NewGoWithTheFlow(util.FlowJSON, os.Getenv("NETWORK"), false, 1)
	events, err := CreateMinterController(g, "minterController1")
	assert.NoError(t, err)

	_, err = util.GetUUID(g, "minterController1", "MinterController")
	assert.NoError(t, err)

	// Test event
	util.NewExpectedEvent("FiatToken", "MinterControllerCreated").AssertHasKey(t, events[0], "resourceId")
}

func TestController_MasterMinterConfigureMinterController(t *testing.T) {
	g := gwtf.NewGoWithTheFlow(util.FlowJSON, os.Getenv("NETWORK"), false, 1)

	_, err := CreateMinter(g, "minter")
	assert.NoError(t, err)

	minterController, err := util.GetUUID(g, "minterController1", "MinterController")
	assert.NoError(t, err)

	minter, err := util.GetUUID(g, "minter", "Minter")
	assert.NoError(t, err)

	events, err := owner.ConfigureMinterController(g, minterController, minter, "owner")
	assert.NoError(t, err)

	managedMinter, err := GetManagedMinter(g, minterController)
	assert.NoError(t, err)
	assert.Equal(t, minter, managedMinter)

	// Test event
	util.NewExpectedEvent("FiatToken", "ControllerConfigured").
		AddField("controller", strconv.Itoa(int(minterController))).
		AddField("minter", strconv.Itoa(int(minter))).
		AssertEqual(t, events[0])
}

func TestController_ConfigureMinterAllowance(t *testing.T) {
	g := gwtf.NewGoWithTheFlow(util.FlowJSON, os.Getenv("NETWORK"), false, 1)

	minterController, err := util.GetUUID(g, "minterController1", "MinterController")
	assert.NoError(t, err)
	minter, err := util.GetUUID(g, "minter", "Minter")
	assert.NoError(t, err)

	allowanceInput := "500.00000000"
	events, err := ConfigureMinterAllowance(g, "minterController1", allowanceInput)
	assert.NoError(t, err)

	allowance, err := GetMinterAllowance(g, minter)
	assert.NoError(t, err)
	expected, err := cadence.NewUFix64(allowanceInput)
	assert.NoError(t, err)
	assert.Equal(t, expected, allowance)

	// Test event
	util.NewExpectedEvent("FiatToken", "MinterConfigured").
		AddField("controller", strconv.Itoa(int(minterController))).
		AddField("minter", strconv.Itoa(int(minter))).
		AddField("allowance", allowanceInput).
		AssertEqual(t, events[0])
}

func TestController_IncreaseMinterAllowance(t *testing.T) {
	g := gwtf.NewGoWithTheFlow(util.FlowJSON, os.Getenv("NETWORK"), false, 1)

	minterController, err := util.GetUUID(g, "minterController1", "MinterController")
	assert.NoError(t, err)
	minter, err := util.GetUUID(g, "minter", "Minter")
	assert.NoError(t, err)
	initAllowance, err := GetMinterAllowance(g, minter)
	assert.NoError(t, err)

	allowanceIncr := "500.00000000"
	events, err := IncreaseOrDecreaseMinterAllowance(g, "minterController1", allowanceIncr, 1)
	assert.NoError(t, err)

	postAllowance, err := GetMinterAllowance(g, minter)
	assert.NoError(t, err)
	expectedDelta, err := cadence.NewUFix64(allowanceIncr)
	assert.NoError(t, err)
	assert.Equal(t, expectedDelta, postAllowance-initAllowance)

	// Test event
	// allowance (500.0) + inc (500.0)
	expectedAllowance := "1000.00000000"
	util.NewExpectedEvent("FiatToken", "MinterConfigured").
		AddField("controller", strconv.Itoa(int(minterController))).
		AddField("minter", strconv.Itoa(int(minter))).
		AddField("allowance", expectedAllowance).
		AssertEqual(t, events[0])
}

func TestController_DecreaseMinterAllowance(t *testing.T) {
	g := gwtf.NewGoWithTheFlow(util.FlowJSON, os.Getenv("NETWORK"), false, 1)

	minterController, err := util.GetUUID(g, "minterController1", "MinterController")
	assert.NoError(t, err)
	minter, err := util.GetUUID(g, "minter", "Minter")
	assert.NoError(t, err)
	initAllowance, err := GetMinterAllowance(g, minter)
	assert.NoError(t, err)

	var allowanceDecr = "500.00000000"
	events, err := IncreaseOrDecreaseMinterAllowance(g, "minterController1", allowanceDecr, 0)
	assert.NoError(t, err)

	postAllowance, err := GetMinterAllowance(g, minter)
	assert.NoError(t, err)
	expectedDelta, err := cadence.NewUFix64(allowanceDecr)
	assert.NoError(t, err)
	assert.Equal(t, expectedDelta, initAllowance-postAllowance)

	// Test event
	// allowance (1000.0) + decr (500.0)
	expectedAllowance := "500.00000000"
	util.NewExpectedEvent("FiatToken", "MinterConfigured").
		AddField("controller", strconv.Itoa(int(minterController))).
		AddField("minter", strconv.Itoa(int(minter))).
		AddField("allowance", expectedAllowance).
		AssertEqual(t, events[0])
}

func TestController_RemoveMinter(t *testing.T) {
	g := gwtf.NewGoWithTheFlow(util.FlowJSON, os.Getenv("NETWORK"), false, 1)

	minterController, err := util.GetUUID(g, "minterController1", "MinterController")
	assert.NoError(t, err)
	minter, err := util.GetUUID(g, "minter", "Minter")
	assert.NoError(t, err)

	events, err := RemoveMinter(g, "minterController1")
	assert.NoError(t, err)

	// Minter does not have allowance
	_, err = GetMinterAllowance(g, minter)
	assert.Error(t, err)

	// Test event
	util.NewExpectedEvent("FiatToken", "MinterRemoved").
		AddField("controller", strconv.Itoa(int(minterController))).
		AddField("minter", strconv.Itoa(int(minter))).
		AssertEqual(t, events[0])
}

func TestController_WithoutConfigFailToSetMinterAllowance(t *testing.T) {
	g := gwtf.NewGoWithTheFlow(util.FlowJSON, os.Getenv("NETWORK"), false, 1)

	// minterController2 is without being configured by MasterMinter
	_, err := CreateMinterController(g, "minterController2")
	assert.NoError(t, err)

	// Try Mint should error
	allowanceInput := "500.00000000"
	rawEvents, err := ConfigureMinterAllowance(g, "minterController2", allowanceInput)
	assert.Error(t, err)
	assert.Empty(t, rawEvents)
}

func TestController_MultipleControllerCanConfigureOneMinter(t *testing.T) {
	g := gwtf.NewGoWithTheFlow(util.FlowJSON, os.Getenv("NETWORK"), false, 1)

	// all minterController has been configured by masterMinter
	minterController1, err := util.GetUUID(g, "minterController1", "MinterController")
	assert.NoError(t, err)
	minterController2, err := util.GetUUID(g, "minterController2", "MinterController")
	assert.NoError(t, err)
	minter, err := util.GetUUID(g, "minter", "Minter")
	assert.NoError(t, err)
	_, err = owner.ConfigureMinterController(g, minterController1, minter, "owner")
	assert.NoError(t, err)
	_, err = owner.ConfigureMinterController(g, minterController2, minter, "owner")
	assert.NoError(t, err)

	// mintController1 configures minter allowance
	var controller1Allowance = "50.00000000"
	expectedController1, _ := cadence.NewUFix64(controller1Allowance)
	_, err = ConfigureMinterAllowance(g, "minterController1", controller1Allowance)
	assert.NoError(t, err)

	allowance, err := GetMinterAllowance(g, minter)
	assert.NoError(t, err)
	assert.Equal(t, expectedController1, allowance)

	// mintController2 configures minter allowance
	var controller2Allowance = "12.00000000"
	expectedController2, _ := cadence.NewUFix64(controller2Allowance)
	_, err = ConfigureMinterAllowance(g, "minterController2", controller2Allowance)
	assert.NoError(t, err)

	allowance, err = GetMinterAllowance(g, minter)
	assert.NoError(t, err)
	assert.Equal(t, expectedController2, allowance)
}

func TestController_MasterMinterRemoveController(t *testing.T) {
	g := gwtf.NewGoWithTheFlow(util.FlowJSON, os.Getenv("NETWORK"), false, 1)
	minterController2, err := util.GetUUID(g, "minterController2", "MinterController")
	assert.NoError(t, err)

	events, err := owner.RemoveMinterController(g, minterController2, "owner")
	assert.NoError(t, err)

	_, err = GetManagedMinter(g, minterController2)
	assert.Error(t, err)

	// Test event
	util.NewExpectedEvent("FiatToken", "ControllerRemoved").
		AddField("controller", strconv.Itoa(int(minterController2))).
		AssertEqual(t, events[0])
}

func TestController_RemovedControllerFailToConfigureMinterAllowance(t *testing.T) {
	g := gwtf.NewGoWithTheFlow(util.FlowJSON, os.Getenv("NETWORK"), false, 1)

	minter, err := util.GetUUID(g, "minter", "Minter")
	assert.NoError(t, err)

	initAllowance, err := GetMinterAllowance(g, minter)
	assert.NoError(t, err)

	// Try Mint should error
	var allowanceInput = "500.00000000"
	rawEvents, err := ConfigureMinterAllowance(g, "minterController2", allowanceInput)
	assert.Error(t, err)
	assert.Empty(t, rawEvents)

	postAllowance, err := GetMinterAllowance(g, minter)
	assert.NoError(t, err)

	// Assertions: minter allowance should not change
	assert.Equal(t, postAllowance, initAllowance)
}

func TestControllerMultiSig_removeMinter(t *testing.T) {
	g := gwtf.NewGoWithTheFlow(util.FlowJSON, os.Getenv("NETWORK"), false, 1)

	minterController, err := util.GetUUID(g, "minterController1", "MinterController")
	assert.NoError(t, err)
	minter, err := util.GetUUID(g, "minter", "Minter")
	assert.NoError(t, err)

	// Add New Payload
	currentIndex, err := util.GetTxIndex(g, "minterController1", "MinterController")
	assert.NoError(t, err)
	expectedNewIndex := currentIndex + 1

	// `true` for new payload
	events, err := util.MultiSig_SignAndSubmit(g, true, expectedNewIndex, util.Acct1000, "minterController1", "MinterController", "removeMinter")
	assert.NoError(t, err)

	util.NewExpectedEvent("OnChainMultiSig", "NewPayloadAdded").
		AddField("resourceId", strconv.Itoa(int(minterController))).
		AddField("txIndex", strconv.Itoa(int(expectedNewIndex))).
		AssertEqual(t, events[0])

	// Try to Execute Tx after second signature
	events, err = util.MultiSig_ExecuteTx(g, expectedNewIndex, "owner", "minterController1", "MinterController")
	assert.NoError(t, err)
	util.NewExpectedEvent("FiatToken", "MinterRemoved").
		AddField("controller", strconv.Itoa(int(minterController))).
		AddField("minter", strconv.Itoa(int(minter))).
		AssertEqual(t, events[0])

	_, err = GetMinterAllowance(g, minter)
	assert.Error(t, err)
}

func TestControllerMultiSig_configureMinter(t *testing.T) {
	g := gwtf.NewGoWithTheFlow(util.FlowJSON, os.Getenv("NETWORK"), false, 1)

	minterController, err := util.GetUUID(g, "minterController1", "MinterController")
	assert.NoError(t, err)
	minter, err := util.GetUUID(g, "minter", "Minter")
	assert.NoError(t, err)

	// Add New Payload
	currentIndex, err := util.GetTxIndex(g, "minterController1", "MinterController")
	assert.NoError(t, err)
	expectedNewIndex := currentIndex + 1

	allowanceInput := "5500.00000000"
	a := util.Arg{V: allowanceInput, T: "UFix64"}
	// `true` for new payload
	events, err := util.MultiSig_SignAndSubmit(g, true, expectedNewIndex, util.Acct500_1, "minterController1", "MinterController", "configureMinterAllowance", a)
	assert.NoError(t, err)

	newTxIndex, err := util.GetTxIndex(g, "minterController1", "MinterController")
	assert.NoError(t, err)
	assert.Equal(t, expectedNewIndex, newTxIndex)

	util.NewExpectedEvent("OnChainMultiSig", "NewPayloadAdded").
		AddField("resourceId", strconv.Itoa(int(minterController))).
		AddField("txIndex", strconv.Itoa(int(newTxIndex))).
		AssertEqual(t, events[0])

	// Try to Execute without enough weight. This should error as there is not enough signer yet
	_, err = util.MultiSig_ExecuteTx(g, newTxIndex, "owner", "minter", "Minter")
	assert.Error(t, err)

	// Add Another Payload Signature
	// `false` for new signature for existing paylaod
	events, err = util.MultiSig_SignAndSubmit(g, false, newTxIndex, util.Acct500_2, "minterController1", "MinterController", "configureMinterAllowance", a)
	assert.NoError(t, err)

	util.NewExpectedEvent("OnChainMultiSig", "NewPayloadSigAdded").
		AddField("resourceId", strconv.Itoa(int(minterController))).
		AddField("txIndex", strconv.Itoa(int(newTxIndex))).
		AssertEqual(t, events[0])

	// Try to Execute Tx after second signature
	events, err = util.MultiSig_ExecuteTx(g, newTxIndex, "owner", "minterController1", "MinterController")
	assert.NoError(t, err)
	util.NewExpectedEvent("FiatToken", "MinterConfigured").
		AddField("controller", strconv.Itoa(int(minterController))).
		AddField("minter", strconv.Itoa(int(minter))).
		AddField("allowance", allowanceInput).
		AssertEqual(t, events[0])

	allowance, err := GetMinterAllowance(g, minter)
	assert.NoError(t, err)
	assert.Equal(t, allowanceInput, allowance.String())
}

func TestControllerMultiSig_incrementMinterAllowance(t *testing.T) {
	g := gwtf.NewGoWithTheFlow(util.FlowJSON, os.Getenv("NETWORK"), false, 1)

	minterController, err := util.GetUUID(g, "minterController1", "MinterController")
	assert.NoError(t, err)
	minter, err := util.GetUUID(g, "minter", "Minter")
	assert.NoError(t, err)

	// Add New Payload
	currentIndex, err := util.GetTxIndex(g, "minterController1", "MinterController")
	assert.NoError(t, err)
	expectedNewIndex := currentIndex + 1

	initAllowance, err := GetMinterAllowance(g, minter)
	assert.NoError(t, err)

	incr := "500.00000000"
	a := util.Arg{V: incr, T: "UFix64"}
	// `true` for new payload
	events, err := util.MultiSig_SignAndSubmit(g, true, expectedNewIndex, util.Acct1000, "minterController1", "MinterController", "increaseMinterAllowance", a)
	assert.NoError(t, err)

	util.NewExpectedEvent("OnChainMultiSig", "NewPayloadAdded").
		AddField("resourceId", strconv.Itoa(int(minterController))).
		AddField("txIndex", strconv.Itoa(int(expectedNewIndex))).
		AssertEqual(t, events[0])

	// previous 5500 plus incr 500
	expectedAllowance := "6000.00000000"
	// Try to Execute Tx after second signature
	events, err = util.MultiSig_ExecuteTx(g, expectedNewIndex, "owner", "minterController1", "MinterController")
	assert.NoError(t, err)
	util.NewExpectedEvent("FiatToken", "MinterConfigured").
		AddField("controller", strconv.Itoa(int(minterController))).
		AddField("minter", strconv.Itoa(int(minter))).
		AddField("allowance", expectedAllowance).
		AssertEqual(t, events[0])

	postAllowance, err := GetMinterAllowance(g, minter)
	assert.NoError(t, err)
	assert.Equal(t, incr, (postAllowance - initAllowance).String())
}

func TestControllerMultiSig_decrementMinterAllowance(t *testing.T) {
	g := gwtf.NewGoWithTheFlow(util.FlowJSON, os.Getenv("NETWORK"), false, 1)

	minterController, err := util.GetUUID(g, "minterController1", "MinterController")
	assert.NoError(t, err)
	minter, err := util.GetUUID(g, "minter", "Minter")
	assert.NoError(t, err)

	// Add New Payload
	currentIndex, err := util.GetTxIndex(g, "minterController1", "MinterController")
	assert.NoError(t, err)
	expectedNewIndex := currentIndex + 1

	initAllowance, err := GetMinterAllowance(g, minter)
	assert.NoError(t, err)

	decr := "100.00000000"
	a := util.Arg{V: decr, T: "UFix64"}
	// `true` for new payload
	events, err := util.MultiSig_SignAndSubmit(g, true, expectedNewIndex, util.Acct1000, "minterController1", "MinterController", "decreaseMinterAllowance", a)
	assert.NoError(t, err)

	util.NewExpectedEvent("OnChainMultiSig", "NewPayloadAdded").
		AddField("resourceId", strconv.Itoa(int(minterController))).
		AddField("txIndex", strconv.Itoa(int(expectedNewIndex))).
		AssertEqual(t, events[0])

	// previous 5500 + incr 500 - decr 100
	expectedAllowance := "5900.00000000"
	// Try to Execute Tx after second signature
	events, err = util.MultiSig_ExecuteTx(g, expectedNewIndex, "owner", "minterController1", "MinterController")
	assert.NoError(t, err)
	util.NewExpectedEvent("FiatToken", "MinterConfigured").
		AddField("controller", strconv.Itoa(int(minterController))).
		AddField("minter", strconv.Itoa(int(minter))).
		AddField("allowance", expectedAllowance).
		AssertEqual(t, events[0])

	postAllowance, err := GetMinterAllowance(g, minter)
	assert.NoError(t, err)
	assert.Equal(t, decr, (initAllowance - postAllowance).String())
}

func TestControllerMultiSig_UnknowMethodFails(t *testing.T) {
	g := gwtf.NewGoWithTheFlow(util.FlowJSON, os.Getenv("NETWORK"), false, 1)
	mc := util.Arg{V: uint64(222), T: "UInt64"}
	m := util.Arg{V: uint64(111), T: "UInt64"}

	txIndex, err := util.GetTxIndex(g, "minterController1", "MinterController")
	assert.NoError(t, err)

	_, err = util.MultiSig_SignAndSubmit(g, true, txIndex+1, util.Acct1000, "minterController1", "MinterController", "UKNOWMETHODController", m, mc)
	assert.NoError(t, err)

	newTxIndex, err := util.GetTxIndex(g, "minterController1", "MinterController")
	assert.NoError(t, err)

	_, err = util.MultiSig_ExecuteTx(g, newTxIndex, "owner", "minterController1", "MinterController")
	assert.Error(t, err)
}

func TestControllerMultiSig_CanRemoveKey(t *testing.T) {
	g := gwtf.NewGoWithTheFlow(util.FlowJSON, os.Getenv("NETWORK"), false, 1)
	pk250_1 := g.Account(util.Acct250_1).Key().ToConfig().PrivateKey.PublicKey().String()

	k := util.Arg{V: pk250_1[2:], T: "String"}

	hasKey, err := util.ContainsKey(g, "minterController1", "MinterController", pk250_1[2:])
	assert.NoError(t, err)
	assert.Equal(t, hasKey, true)

	txIndex, err := util.GetTxIndex(g, "minterController1", "MinterController")
	newTxIndex := txIndex + 1
	assert.NoError(t, err)

	_, err = util.MultiSig_SignAndSubmit(g, true, newTxIndex, util.Acct1000, "minterController1", "MinterController", "removeKey", k)
	assert.NoError(t, err)

	_, err = util.MultiSig_ExecuteTx(g, newTxIndex, "owner", "minterController1", "MinterController")
	assert.NoError(t, err)

	hasKey, err = util.ContainsKey(g, "minterController1", "MinterController", pk250_1[2:])
	assert.NoError(t, err)
	assert.Equal(t, hasKey, false)
}

func TestControllerMultiSig_CanAddKey(t *testing.T) {
	g := gwtf.NewGoWithTheFlow(util.FlowJSON, os.Getenv("NETWORK"), false, 1)
	pk250_1 := g.Account(util.Acct250_1).Key().ToConfig().PrivateKey.PublicKey().String()
	k := util.Arg{V: pk250_1[2:], T: "String"}
	w := util.Arg{V: "250.00000000", T: "UFix64"}
	sa := util.Arg{V: uint8(1), T: "UInt8"}

	hasKey, err := util.ContainsKey(g, "minterController1", "MinterController", pk250_1[2:])
	assert.NoError(t, err)
	assert.Equal(t, hasKey, false)

	txIndex, err := util.GetTxIndex(g, "minterController1", "MinterController")
	newTxIndex := txIndex + 1
	assert.NoError(t, err)

	_, err = util.MultiSig_SignAndSubmit(g, true, newTxIndex, util.Acct1000, "minterController1", "MinterController", "configureKey", k, w, sa)
	assert.NoError(t, err)

	_, err = util.MultiSig_ExecuteTx(g, newTxIndex, "owner", "minterController1", "MinterController")
	assert.NoError(t, err)

	hasKey, err = util.ContainsKey(g, "minterController1", "MinterController", pk250_1[2:])
	assert.NoError(t, err)
	assert.Equal(t, hasKey, true)

	weight, err := util.GetKeyWeight(g, util.Acct250_1, "minterController1", "MinterController")
	assert.NoError(t, err)
	assert.Equal(t, w.V, weight.String())
}
