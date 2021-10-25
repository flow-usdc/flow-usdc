package vault

import (
	"strconv"
	"testing"

	"os"

	"github.com/bjartek/go-with-the-flow/v2/gwtf"
	util "github.com/flow-usdc/flow-usdc"
	"github.com/onflow/cadence"
	"github.com/stretchr/testify/assert"
)

func TestApproval(t *testing.T) {
	g := gwtf.NewGoWithTheFlow(util.FlowJSON, os.Getenv("NETWORK"), false, 1)

	_, err := AddVaultToAccount(g, "allowance")
	assert.NoError(t, err)

	toUuid, err := util.GetUUID(g, "allowance", "Vault")
	assert.NoError(t, err)
	fromUuid, err := util.GetUUID(g, "owner", "Vault")
	assert.NoError(t, err)

	allowanceAmount := "16.00000000"
	events, err := Approve(g, "owner", toUuid, allowanceAmount)
	assert.NoError(t, err)

	a, err := GetAllowance(g, "owner", toUuid)
	assert.NoError(t, err)
	assert.Equal(t, allowanceAmount, a.String())

	// Test event
	util.NewExpectedEvent("FiatToken", "Approval").
		AddField("from", strconv.Itoa(int(fromUuid))).
		AddField("to", strconv.Itoa(int(toUuid))).
		AddField("amount", allowanceAmount).
		AssertEqual(t, events[0])

}

func TestWithdrawAllowanceValidReq(t *testing.T) {
	g := gwtf.NewGoWithTheFlow(util.FlowJSON, os.Getenv("NETWORK"), false, 1)

	uuid, err := util.GetUUID(g, "allowance", "Vault")
	assert.NoError(t, err)

	initFromBalance, err := util.GetBalance(g, "owner")
	assert.NoError(t, err)
	initToBalance, err := util.GetBalance(g, "allowance")
	assert.NoError(t, err)
	initAllowance, err := GetAllowance(g, "owner", uuid)
	assert.NoError(t, err)

	withdrawAmount := "10.00000000"
	events, err := WithdrawAllowance(g, "owner", "owner", "allowance", withdrawAmount)
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
	fromUuid, err := util.GetUUID(g, "owner", "Vault")
	assert.NoError(t, err)
	assert.NoError(t, err)
	util.NewExpectedEvent("FiatToken", "FiatTokenWithdrawn").
		AddField("amount", withdrawAmount).
		AddField("from", strconv.Itoa(int(fromUuid))).
		AssertEqual(t, events[0])

	fromAddr := util.GetAccountAddr(g, "owner")
	util.NewExpectedEvent("FiatToken", "TokensWithdrawn").
		AddField("amount", withdrawAmount).
		AddField("from", fromAddr).
		AssertEqual(t, events[1])

	uuid, err = util.GetUUID(g, "allowance", "Vault")
	assert.NoError(t, err)
	util.NewExpectedEvent("FiatToken", "FiatTokenDeposited").
		AddField("amount", withdrawAmount).
		AddField("to", strconv.Itoa(int(uuid))).
		AssertEqual(t, events[2])

	toAddr := util.GetAccountAddr(g, "allowance")
	util.NewExpectedEvent("FiatToken", "TokensDeposited").
		AddField("amount", withdrawAmount).
		AddField("to", toAddr).
		AssertEqual(t, events[3])

}

func TestWithdrawAllowanceWithoutAllowance(t *testing.T) {
	g := gwtf.NewGoWithTheFlow(util.FlowJSON, os.Getenv("NETWORK"), false, 1)

	_, err := AddVaultToAccount(g, "non-allowance")
	assert.NoError(t, err)

	uuid, err := util.GetUUID(g, "non-allowance", "Vault")
	assert.NoError(t, err)

	initFromBalance, err := util.GetBalance(g, "owner")
	assert.NoError(t, err)
	initToBalance, err := util.GetBalance(g, "non-allowance")
	assert.NoError(t, err)

	_, err = GetAllowance(g, "owner", uuid)
	assert.Error(t, err)
	rawEvents, err := WithdrawAllowance(g, "owner", "owner", "non-allowance", "10.00000000")
	assert.Error(t, err)
	assert.Empty(t, rawEvents)

	postFromBalance, err := util.GetBalance(g, "owner")
	assert.NoError(t, err)
	postToBalance, err := util.GetBalance(g, "non-allowance")
	assert.NoError(t, err)

	assert.Equal(t, "0.00000000", (initFromBalance - postFromBalance).String())
	assert.Equal(t, "0.00000000", (postToBalance - initToBalance).String())
}

func TestWithdrawAllowanceAboveAllowance(t *testing.T) {
	g := gwtf.NewGoWithTheFlow(util.FlowJSON, os.Getenv("NETWORK"), false, 1)

	uuid, err := util.GetUUID(g, "allowance", "Vault")
	assert.NoError(t, err)

	initAllowance, err := GetAllowance(g, "owner", uuid)
	assert.NoError(t, err)

	reqAllowance, err := cadence.NewUFix64("1.00000000")
	assert.NoError(t, err)

	reqAllowance += initAllowance

	rawEvents, err := WithdrawAllowance(g, "owner", "owner", "allowance", reqAllowance.String())
	assert.Error(t, err)
	assert.Empty(t, rawEvents)

	postAllowance, err := GetAllowance(g, "owner", uuid)
	assert.NoError(t, err)

	assert.Equal(t, initAllowance, postAllowance)
}

func TestSetZeroApprovalRemoves(t *testing.T) {
	g := gwtf.NewGoWithTheFlow(util.FlowJSON, os.Getenv("NETWORK"), false, 1)

	uuid, err := util.GetUUID(g, "allowance", "Vault")
	assert.NoError(t, err)

	_, err = Approve(g, "owner", uuid, "0.00000000")
	assert.NoError(t, err)

	_, err = GetAllowance(g, "owner", uuid)
	assert.Error(t, err)
}

func TestIncreaseAllowance(t *testing.T) {
	g := gwtf.NewGoWithTheFlow(util.FlowJSON, os.Getenv("NETWORK"), false, 1)

	uuid, err := util.GetUUID(g, "allowance", "Vault")
	assert.NoError(t, err)

	allowanceAmount := "10.00000000"
	_, err = Approve(g, "owner", uuid, allowanceAmount)
	assert.NoError(t, err)

	initAllowance, err := GetAllowance(g, "owner", uuid)
	assert.NoError(t, err)
	assert.Equal(t, allowanceAmount, initAllowance.String())

	events, err := IncreaseOrDecreaseAlowance(g, "owner", uuid, allowanceAmount, 1)
	assert.NoError(t, err)

	postAllowance, err := GetAllowance(g, "owner", uuid)
	assert.NoError(t, err)
	assert.Equal(t, allowanceAmount, (postAllowance - initAllowance).String())

	// Test event
	// initial allowance(10) + increased allowance(10)
	postAllowanceAmount := "20.00000000"
	fromUuid, err := util.GetUUID(g, "owner", "Vault")
	assert.NoError(t, err)
	util.NewExpectedEvent("FiatToken", "Approval").
		AddField("from", strconv.Itoa(int(fromUuid))).
		AddField("to", strconv.Itoa(int(uuid))).
		AddField("amount", postAllowanceAmount).
		AssertEqual(t, events[0])
}

func TestDecreaseAllowance(t *testing.T) {
	g := gwtf.NewGoWithTheFlow(util.FlowJSON, os.Getenv("NETWORK"), false, 1)

	uuid, err := util.GetUUID(g, "allowance", "Vault")
	assert.NoError(t, err)

	allowanceAmount := "10.00000000"
	decrAmount := "3.00000000"
	_, err = Approve(g, "owner", uuid, allowanceAmount)
	assert.NoError(t, err)

	initAllowance, err := GetAllowance(g, "owner", uuid)
	assert.NoError(t, err)

	events, err := IncreaseOrDecreaseAlowance(g, "owner", uuid, decrAmount, 0)
	assert.NoError(t, err)

	postAllowance, err := GetAllowance(g, "owner", uuid)
	assert.NoError(t, err)
	assert.Equal(t, decrAmount, (initAllowance - postAllowance).String())

	// Test event
	// initial allowance(10) + increased allowance(3)
	postAllowanceAmount := "7.00000000"
	fromUuid, err := util.GetUUID(g, "owner", "Vault")
	assert.NoError(t, err)
	util.NewExpectedEvent("FiatToken", "Approval").
		AddField("from", strconv.Itoa(int(fromUuid))).
		AddField("to", strconv.Itoa(int(uuid))).
		AddField("amount", postAllowanceAmount).
		AssertEqual(t, events[0])
}

func TestMultiSig_Apporval(t *testing.T) {
	g := gwtf.NewGoWithTheFlow(util.FlowJSON, os.Getenv("NETWORK"), false, 1)

	_, err := AddVaultToAccount(g, "vaulted-account")
	assert.NoError(t, err)

	toUuid, err := util.GetUUID(g, "allowance", "Vault")
	assert.NoError(t, err)
	fromUuid, err := util.GetUUID(g, "vaulted-account", "Vault")
	assert.NoError(t, err)
	allowanceAmount := "16.00000000"

	// Add New Payload
	currentIndex, err := util.GetTxIndex(g, "vaulted-account", "Vault")
	assert.NoError(t, err)
	expectedNewIndex := currentIndex + 1

	resourceId := util.Arg{V: toUuid, T: "UInt64"}
	amount := util.Arg{V: allowanceAmount, T: "UFix64"}

	// `true` for new payload
	_, err = util.MultiSig_SignAndSubmit(g, true, expectedNewIndex, util.Acct1000, "vaulted-account", "Vault", "approval", resourceId, amount)
	assert.NoError(t, err)

	newTxIndex, err := util.GetTxIndex(g, "vaulted-account", "Vault")
	assert.NoError(t, err)
	assert.Equal(t, expectedNewIndex, newTxIndex)

	events, err := util.MultiSig_ExecuteTx(g, newTxIndex, "owner", "vaulted-account", "Vault")
	assert.NoError(t, err)

	// Test event
	util.NewExpectedEvent("FiatToken", "Approval").
		AddField("from", strconv.Itoa(int(fromUuid))).
		AddField("to", strconv.Itoa(int(toUuid))).
		AddField("amount", allowanceAmount).
		AssertEqual(t, events[0])

	a, err := GetAllowance(g, "vaulted-account", toUuid)
	assert.NoError(t, err)
	assert.Equal(t, allowanceAmount, a.String())
}

func TestMultiSig_IncreaseAllowance(t *testing.T) {
	g := gwtf.NewGoWithTheFlow(util.FlowJSON, os.Getenv("NETWORK"), false, 1)

	toUuid, err := util.GetUUID(g, "allowance", "Vault")
	assert.NoError(t, err)
	fromUuid, err := util.GetUUID(g, "vaulted-account", "Vault")
	assert.NoError(t, err)
	increaseAmount := "4.00000000"

	// Add New Payload
	currentIndex, err := util.GetTxIndex(g, "vaulted-account", "Vault")
	assert.NoError(t, err)
	expectedNewIndex := currentIndex + 1

	resourceId := util.Arg{V: toUuid, T: "UInt64"}
	amount := util.Arg{V: increaseAmount, T: "UFix64"}

	// `true` for new payload
	_, err = util.MultiSig_SignAndSubmit(g, true, expectedNewIndex, util.Acct1000, "vaulted-account", "Vault", "increaseAllowance", resourceId, amount)
	assert.NoError(t, err)

	newTxIndex, err := util.GetTxIndex(g, "vaulted-account", "Vault")
	assert.NoError(t, err)
	assert.Equal(t, expectedNewIndex, newTxIndex)

	init, err := GetAllowance(g, "vaulted-account", toUuid)
	assert.NoError(t, err)

	events, err := util.MultiSig_ExecuteTx(g, newTxIndex, "owner", "vaulted-account", "Vault")
	assert.NoError(t, err)

	// Test event
	// Total allowed = 16 + 4
	util.NewExpectedEvent("FiatToken", "Approval").
		AddField("from", strconv.Itoa(int(fromUuid))).
		AddField("to", strconv.Itoa(int(toUuid))).
		AddField("amount", "20.00000000").
		AssertEqual(t, events[0])

	post, err := GetAllowance(g, "vaulted-account", toUuid)
	assert.NoError(t, err)
	assert.Equal(t, increaseAmount, (post - init).String())
}

func TestMultiSig_DecreaseAllowance(t *testing.T) {
	g := gwtf.NewGoWithTheFlow(util.FlowJSON, os.Getenv("NETWORK"), false, 1)

	toUuid, err := util.GetUUID(g, "allowance", "Vault")
	assert.NoError(t, err)
	fromUuid, err := util.GetUUID(g, "vaulted-account", "Vault")
	assert.NoError(t, err)
	decreaseAmount := "5.00000000"

	// Add New Payload
	currentIndex, err := util.GetTxIndex(g, "vaulted-account", "Vault")
	assert.NoError(t, err)
	expectedNewIndex := currentIndex + 1

	resourceId := util.Arg{V: toUuid, T: "UInt64"}
	amount := util.Arg{V: decreaseAmount, T: "UFix64"}

	// `true` for new payload
	_, err = util.MultiSig_SignAndSubmit(g, true, expectedNewIndex, util.Acct1000, "vaulted-account", "Vault", "decreaseAllowance", resourceId, amount)
	assert.NoError(t, err)

	newTxIndex, err := util.GetTxIndex(g, "vaulted-account", "Vault")
	assert.NoError(t, err)
	assert.Equal(t, expectedNewIndex, newTxIndex)

	init, err := GetAllowance(g, "vaulted-account", toUuid)
	assert.NoError(t, err)

	events, err := util.MultiSig_ExecuteTx(g, newTxIndex, "owner", "vaulted-account", "Vault")
	assert.NoError(t, err)

	// Test event
	// Total allowed = 16 + 4
	util.NewExpectedEvent("FiatToken", "Approval").
		AddField("from", strconv.Itoa(int(fromUuid))).
		AddField("to", strconv.Itoa(int(toUuid))).
		AddField("amount", "15.00000000").
		AssertEqual(t, events[0])

	post, err := GetAllowance(g, "vaulted-account", toUuid)
	assert.NoError(t, err)
	assert.Equal(t, decreaseAmount, (init - post).String())
}
