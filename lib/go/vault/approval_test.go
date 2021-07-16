package vault

import (
	"strconv"
	"testing"

	"github.com/bjartek/go-with-the-flow/gwtf"
	util "github.com/flow-usdc/flow-usdc"
	"github.com/onflow/cadence"
	"github.com/stretchr/testify/assert"
)

func TestApproval(t *testing.T) {
	g := gwtf.NewGoWithTheFlow("../../../flow.json")

	_, err := AddVaultToAccount(g, "allowance")
	assert.NoError(t, err)

	toUuid, err := util.GetVaultUUID(g, "allowance")
	assert.NoError(t, err)
	fromUuid, err := util.GetVaultUUID(g, "owner")
	assert.NoError(t, err)

    allowanceAmount := "16.00000000"
    rawEvents, err := Approve(g, "owner", toUuid, allowanceAmount)
	assert.NoError(t, err)

	a, err := GetAllowance(g, "owner", toUuid)
	assert.NoError(t, err)
	assert.Equal(t, allowanceAmount, a.String())

	// Test event
	event := util.ParseTestEvent(rawEvents[0])
	util.NewExpectedEvent("Approval").
        AddField("from", strconv.Itoa(int(fromUuid))).
        AddField("to", strconv.Itoa(int(toUuid))).
        AddField("amount", allowanceAmount).
        AssertEqual(t, event)

}

func TestWithdrawAllowanceValidReq(t *testing.T) {
	g := gwtf.NewGoWithTheFlow("../../../flow.json")

	uuid, err := util.GetVaultUUID(g, "allowance")
	assert.NoError(t, err)

	initFromBalance, err := util.GetBalance(g, "owner")
	assert.NoError(t, err)
	initToBalance, err := util.GetBalance(g, "allowance")
	assert.NoError(t, err)
	initAllowance, err := GetAllowance(g, "owner", uuid)
	assert.NoError(t, err)

    withdrawAmount := "10.00000000" 
    rawEvents, err := WithdrawAllowance(g, "owner", "owner", "allowance", withdrawAmount)
	assert.NoError(t, err)

	postFromBalance, err := util.GetBalance(g, "owner")
	assert.NoError(t, err)
	postToBalance, err := util.GetBalance(g, "allowance")
	assert.NoError(t, err)
	postAllowance, err := GetAllowance(g, "owner", uuid)
	assert.NoError(t, err)

	assert.Equal(t, "10.00000000", (initFromBalance - postFromBalance).String())
	assert.Equal(t, "10.00000000", (postToBalance - initToBalance).String())
	assert.Equal(t, "10.00000000", (initAllowance - postAllowance).String())

	// Test events
	event0 := util.ParseTestEvent(rawEvents[0])
    fromUuid, err := util.GetVaultUUID(g, "owner")
    assert.NoError(t, err)
    assert.NoError(t, err)
	util.NewExpectedEvent("FiatTokenWithdrawn").
        AddField("amount", withdrawAmount).
        AddField("from", strconv.Itoa(int(fromUuid))).
        AssertEqual(t, event0)

	event1 := util.ParseTestEvent(rawEvents[1])
    fromAddr := util.GetAccountAddr(g, "owner")
	util.NewExpectedEvent("TokensWithdrawn").
        AddField("amount", withdrawAmount).
        AddField("from", fromAddr).
        AssertEqual(t, event1)

	event2 := util.ParseTestEvent(rawEvents[2])
    uuid, err = util.GetVaultUUID(g, "allowance")
    assert.NoError(t, err)
	util.NewExpectedEvent("FiatTokenDeposited").
        AddField("amount", withdrawAmount).
        AddField("to", strconv.Itoa(int(uuid))).
        AssertEqual(t, event2)

	event3 := util.ParseTestEvent(rawEvents[3])
    toAddr := util.GetAccountAddr(g, "allowance")
	util.NewExpectedEvent("TokensWithdrawn").
        AddField("amount", withdrawAmount).
        AddField("from", toAddr).
        AssertEqual(t, event3)

}

func TestWithdrawAllowanceWithoutAllowance(t *testing.T) {
	g := gwtf.NewGoWithTheFlow("../../../flow.json")

	_, err := AddVaultToAccount(g, "non-allowance")
	assert.NoError(t, err)

	uuid, err := util.GetVaultUUID(g, "non-allowance")
	assert.NoError(t, err)

	initFromBalance, err := util.GetBalance(g, "owner")
	assert.NoError(t, err)
	initToBalance, err := util.GetBalance(g, "non-allowance")
	assert.NoError(t, err)

	_, err = GetAllowance(g, "owner", uuid)
	assert.Error(t, err)
    rawEvents, err := WithdrawAllowance(g, "owner", "owner", "non-allowance", "10.0")
	assert.Error(t, err)

	postFromBalance, err := util.GetBalance(g, "owner")
	assert.NoError(t, err)
	postToBalance, err := util.GetBalance(g, "non-allowance")
	assert.NoError(t, err)

	assert.Equal(t, "0.00000000", (initFromBalance - postFromBalance).String())
	assert.Equal(t, "0.00000000", (postToBalance - initToBalance).String())
    assert.Empty(t, rawEvents)
}

func TestWithdrawAllowanceAboveAllowance(t *testing.T) {
	g := gwtf.NewGoWithTheFlow("../../../flow.json")

	uuid, err := util.GetVaultUUID(g, "allowance")
	assert.NoError(t, err)

	initAllowance, err := GetAllowance(g, "owner", uuid)
	assert.NoError(t, err)

	reqAllowance, err := cadence.NewUFix64("1.0")
	assert.NoError(t, err)

	reqAllowance += initAllowance

    rawEvents, err := WithdrawAllowance(g, "owner", "owner", "allowance", reqAllowance.String())
	assert.Error(t, err)

	postAllowance, err := GetAllowance(g, "owner", uuid)
	assert.NoError(t, err)

	assert.Equal(t, initAllowance, postAllowance)
    assert.Empty(t, rawEvents)
}

func TestSetZeroApprovalRemoves(t *testing.T) {
	g := gwtf.NewGoWithTheFlow("../../../flow.json")

	uuid, err := util.GetVaultUUID(g, "allowance")
	assert.NoError(t, err)

	_, err = Approve(g, "owner", uuid, "0.0")
	assert.NoError(t, err)

	_, err = GetAllowance(g, "owner", uuid)
	assert.Error(t, err)
}

func TestIncreaseAllowance(t *testing.T) {
	g := gwtf.NewGoWithTheFlow("../../../flow.json")

	uuid, err := util.GetVaultUUID(g, "allowance")
	assert.NoError(t, err)

	_, err = Approve(g, "owner", uuid, "10.0")
	assert.NoError(t, err)

	initAllowance, err := GetAllowance(g, "owner", uuid)
	assert.NoError(t, err)
	assert.Equal(t, "10.00000000", initAllowance.String())

    rawEvents, err := IncreaseOrDecreaseAlowance(g, "owner", uuid, "10.0", 1)
	assert.NoError(t, err)

	postAllowance, err := GetAllowance(g, "owner", uuid)
	assert.NoError(t, err)
	assert.Equal(t, "10.00000000", (postAllowance - initAllowance).String())
}

func TestDecreaseAllowance(t *testing.T) {
	g := gwtf.NewGoWithTheFlow("../../../flow.json")

	uuid, err := util.GetVaultUUID(g, "allowance")
	assert.NoError(t, err)

	_, err = Approve(g, "owner", uuid, "10.0")
	assert.NoError(t, err)

	initAllowance, err := GetAllowance(g, "owner", uuid)
	assert.NoError(t, err)

    rawEvents, err := IncreaseOrDecreaseAlowance(g, "owner", uuid, "3.0", 0)
	assert.NoError(t, err)

	postAllowance, err := GetAllowance(g, "owner", uuid)
	assert.NoError(t, err)
	assert.Equal(t, "3.00000000", (initAllowance - postAllowance).String())
}
