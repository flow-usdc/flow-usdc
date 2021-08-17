package mint

import (
	"strconv"
	"testing"

	"github.com/bjartek/go-with-the-flow/gwtf"
	util "github.com/flow-usdc/flow-usdc"
	"github.com/flow-usdc/flow-usdc/owner"
	"github.com/onflow/cadence"
	"github.com/stretchr/testify/assert"
)

func TestController_Create(t *testing.T) {
	g := gwtf.NewGoWithTheFlow("../../../flow.json")
	events, err := CreateMinterController(g, "minterController1")
	assert.NoError(t, err)

	_, err = util.GetUUID(g, "minterController1", "MinterController")
	assert.NoError(t, err)

	// Test event
	util.NewExpectedEvent("FiatToken", "MinterControllerCreated").AssertHasKey(t, events[0], "resourceId")
}

func TestController_MasterMinterConfigureMinterController(t *testing.T) {
	g := gwtf.NewGoWithTheFlow("../../../flow.json")

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
	g := gwtf.NewGoWithTheFlow("../../../flow.json")

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
	g := gwtf.NewGoWithTheFlow("../../../flow.json")

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
	g := gwtf.NewGoWithTheFlow("../../../flow.json")

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
	g := gwtf.NewGoWithTheFlow("../../../flow.json")

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
	g := gwtf.NewGoWithTheFlow("../../../flow.json")

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
	g := gwtf.NewGoWithTheFlow("../../../flow.json")

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
	g := gwtf.NewGoWithTheFlow("../../../flow.json")
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
	g := gwtf.NewGoWithTheFlow("../../../flow.json")

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

func TestMultiSig_ConfigureMinterController(t *testing.T) {
	g := gwtf.NewGoWithTheFlow("../../../flow.json")
	minterController := uint64(222)
	minter := uint64(111)

	currentIndex, err := util.GetTxIndex(g, "owner", "MasterMinter")
	assert.NoError(t, err)
	expectedNewIndex := currentIndex + 1

	m := util.Arg{V: minter, T: "UInt64"}
	mc := util.Arg{V: minterController, T: "UInt64"}
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

		// This should error as there is not enough signer yet
	_, err = util.MultiSig_ExecuteTx(g, newTxIndex, "owner", "owner", "MasterMinter")
	assert.Error(t, err)

	_, err = util.MultiSig_SignAndSubmit(g, false, newTxIndex, util.Acct500_2, "owner", "MasterMinter", "configureMinterController", m, mc)
	assert.NoError(t, err)

	_, err = util.MultiSig_ExecuteTx(g, newTxIndex, "owner", "owner", "MasterMinter")
	assert.NoError(t, err)

	managedMinter, err := GetManagedMinter(g, minterController)
	assert.NoError(t, err)
	assert.Equal(t, minter, managedMinter)
}

func TestMultiSig_MinterControllerUnknowMethodFails(t *testing.T) {
	g := gwtf.NewGoWithTheFlow("../../../flow.json")
	minterController := uint64(222)
	minter := uint64(111)
	m := util.Arg{V: minter, T: "UInt64"}
	mc := util.Arg{V: minterController, T: "UInt64"}

	txIndex, err := util.GetTxIndex(g, "owner", "MasterMinter")
	assert.NoError(t, err)

	_, err = util.MultiSig_SignAndSubmit(g, true, txIndex+1, util.Acct1000, "owner", "MasterMinter", "configureUKNOWMETHODController", m, mc)
	assert.NoError(t, err)

	newTxIndex, err := util.GetTxIndex(g, "owner", "MasterMinter")
	assert.NoError(t, err)

	_, err = util.MultiSig_ExecuteTx(g, newTxIndex, "owner", "owner", "MasterMinter")
	assert.Error(t, err)
}
