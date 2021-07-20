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
	rawEvents, err := CreateMinterController(g, "minterController1")
	assert.NoError(t, err)

	_, err = GetMinterControllerUUID(g, "minterController1")
	assert.NoError(t, err)

	// Test event
	event := util.ParseTestEvent(rawEvents[0])
	util.NewExpectedEvent("MinterControllerCreated").AssertHasKey(t, event, "resourceId")
}

func TestController_MasterMinterConfigureMinterController(t *testing.T) {
	g := gwtf.NewGoWithTheFlow("../../../flow.json")

	_, err := CreateMinter(g, "minter")
	assert.NoError(t, err)

	minterController, err := GetMinterControllerUUID(g, "minterController1")
	assert.NoError(t, err)

	minter, err := GetMinterUUID(g, "minter")
	assert.NoError(t, err)

	rawEvents, err := owner.ConfigureMinterController(g, minterController, minter, "owner")
	assert.NoError(t, err)

	managedMinter, err := GetManagedMinter(g, minterController)
	assert.NoError(t, err)
	assert.Equal(t, minter, managedMinter)

	// Test event
	event := util.ParseTestEvent(rawEvents[0])
	util.NewExpectedEvent("ControllerConfigured").
		AddField("controller", strconv.Itoa(int(minterController))).
		AddField("minter", strconv.Itoa(int(minter))).
		AssertEqual(t, event)
}

func TestController_ConfigureMinterAllowance(t *testing.T) {
	g := gwtf.NewGoWithTheFlow("../../../flow.json")

	minterController, err := GetMinterControllerUUID(g, "minterController1")
	assert.NoError(t, err)
	minter, err := GetMinterUUID(g, "minter")
	assert.NoError(t, err)

	allowanceInput := "500.00000000"
	rawEvents, err := ConfigureMinterAllowance(g, "minterController1", allowanceInput)
	assert.NoError(t, err)

	allowance, err := GetMinterAllowance(g, minter)
	assert.NoError(t, err)
	expected, err := cadence.NewUFix64(allowanceInput)
	assert.NoError(t, err)
	assert.Equal(t, expected, allowance)

	// Test event
	event := util.ParseTestEvent(rawEvents[0])
	util.NewExpectedEvent("MinterConfigured").
		AddField("controller", strconv.Itoa(int(minterController))).
		AddField("minter", strconv.Itoa(int(minter))).
		AddField("allowance", allowanceInput).
		AssertEqual(t, event)
}

func TestController_IncreaseMinterAllowance(t *testing.T) {
	g := gwtf.NewGoWithTheFlow("../../../flow.json")

	minterController, err := GetMinterControllerUUID(g, "minterController1")
	assert.NoError(t, err)
	minter, err := GetMinterUUID(g, "minter")
	assert.NoError(t, err)
	initAllowance, err := GetMinterAllowance(g, minter)
	assert.NoError(t, err)

	allowanceIncr := "500.00000000"
	rawEvents, err := IncreaseOrDecreaseMinterAllowance(g, "minterController1", allowanceIncr, 1)
	assert.NoError(t, err)

	postAllowance, err := GetMinterAllowance(g, minter)
	assert.NoError(t, err)
	expectedDelta, err := cadence.NewUFix64(allowanceIncr)
	assert.NoError(t, err)
	assert.Equal(t, expectedDelta, postAllowance-initAllowance)

	// Test event
	// allowance (500.0) + inc (500.0)
	expectedAllowance := "1000.00000000"
	event := util.ParseTestEvent(rawEvents[0])
	util.NewExpectedEvent("MinterConfigured").
		AddField("controller", strconv.Itoa(int(minterController))).
		AddField("minter", strconv.Itoa(int(minter))).
		AddField("allowance", expectedAllowance).
		AssertEqual(t, event)
}

func TestController_DecreaseMinterAllowance(t *testing.T) {
	g := gwtf.NewGoWithTheFlow("../../../flow.json")

	minterController, err := GetMinterControllerUUID(g, "minterController1")
	assert.NoError(t, err)
	minter, err := GetMinterUUID(g, "minter")
	assert.NoError(t, err)
	initAllowance, err := GetMinterAllowance(g, minter)
	assert.NoError(t, err)

	var allowanceDecr = "500.00000000"
	rawEvents, err := IncreaseOrDecreaseMinterAllowance(g, "minterController1", allowanceDecr, 0)
	assert.NoError(t, err)

	postAllowance, err := GetMinterAllowance(g, minter)
	assert.NoError(t, err)
	expectedDelta, err := cadence.NewUFix64(allowanceDecr)
	assert.NoError(t, err)
	assert.Equal(t, expectedDelta, initAllowance-postAllowance)

	// Test event
	// allowance (1000.0) + decr (500.0)
	expectedAllowance := "500.00000000"
	event := util.ParseTestEvent(rawEvents[0])
	util.NewExpectedEvent("MinterConfigured").
		AddField("controller", strconv.Itoa(int(minterController))).
		AddField("minter", strconv.Itoa(int(minter))).
		AddField("allowance", expectedAllowance).
		AssertEqual(t, event)
}

func TestController_RemoveMinter(t *testing.T) {
	g := gwtf.NewGoWithTheFlow("../../../flow.json")

	minterController, err := GetMinterControllerUUID(g, "minterController1")
	assert.NoError(t, err)
	minter, err := GetMinterUUID(g, "minter")
	assert.NoError(t, err)

	rawEvents, err := RemoveMinter(g, "minterController1")
	assert.NoError(t, err)

	// Minter does not have allowance
	_, err = GetMinterAllowance(g, minter)
	assert.Error(t, err)

	// Test event
	event := util.ParseTestEvent(rawEvents[0])
	util.NewExpectedEvent("MinterRemoved").
		AddField("controller", strconv.Itoa(int(minterController))).
		AddField("minter", strconv.Itoa(int(minter))).
		AssertEqual(t, event)
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
	minterController1, err := GetMinterControllerUUID(g, "minterController1")
	assert.NoError(t, err)
	minterController2, err := GetMinterControllerUUID(g, "minterController2")
	assert.NoError(t, err)
	minter, err := GetMinterUUID(g, "minter")
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
	minterController2, err := GetMinterControllerUUID(g, "minterController2")
	assert.NoError(t, err)

	rawEvents, err := owner.RemoveMinterController(g, minterController2, "owner")
	assert.NoError(t, err)

	_, err = GetManagedMinter(g, minterController2)
	assert.Error(t, err)

	// Test event
	event := util.ParseTestEvent(rawEvents[0])
	util.NewExpectedEvent("ControllerRemoved").
		AddField("controller", strconv.Itoa(int(minterController2))).
		AssertEqual(t, event)
}

func TestController_RemovedControllerFailToConfigureMinterAllowance(t *testing.T) {
	g := gwtf.NewGoWithTheFlow("../../../flow.json")

	minter, err := GetMinterUUID(g, "minter")
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
