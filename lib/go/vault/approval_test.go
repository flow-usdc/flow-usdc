package vault

import (
	"testing"

	"github.com/bjartek/go-with-the-flow/gwtf"
	util "github.com/flow-usdc/flow-usdc"
	"github.com/onflow/cadence"
	"github.com/stretchr/testify/assert"
)

func TestApproval(t *testing.T) {
	g := gwtf.NewGoWithTheFlow("../../../flow.json")

	err := AddVaultToAccount(g, "allowance")
	assert.NoError(t, err)

	uuid, err := util.GetVaultUUID(g, "allowance")
	assert.NoError(t, err)

	err = Approve(g, "owner", uuid, "16.0")
	assert.NoError(t, err)

	a, err := GetAllowance(g, "owner", uuid)
	assert.NoError(t, err)
	assert.Equal(t, "16.00000000", a.String())
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

	err = WithdrawAllowance(g, "owner", "owner", "allowance", "10.0")
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
}

func TestWithdrawAllowanceWithoutAllowance(t *testing.T) {
	g := gwtf.NewGoWithTheFlow("../../../flow.json")

	err := AddVaultToAccount(g, "non-allowance")
	assert.NoError(t, err)

	uuid, err := util.GetVaultUUID(g, "non-allowance")
	assert.NoError(t, err)

	initFromBalance, err := util.GetBalance(g, "owner")
	assert.NoError(t, err)
	initToBalance, err := util.GetBalance(g, "non-allowance")
	assert.NoError(t, err)

	_, err = GetAllowance(g, "owner", uuid)
	assert.Error(t, err)
	err = WithdrawAllowance(g, "owner", "owner", "non-allowance", "10.0")
	assert.Error(t, err)

	postFromBalance, err := util.GetBalance(g, "owner")
	assert.NoError(t, err)
	postToBalance, err := util.GetBalance(g, "non-allowance")
	assert.NoError(t, err)

	assert.Equal(t, "0.00000000", (initFromBalance - postFromBalance).String())
	assert.Equal(t, "0.00000000", (postToBalance - initToBalance).String())
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

	err = WithdrawAllowance(g, "owner", "owner", "allowance", reqAllowance.String())
	assert.Error(t, err)

	postAllowance, err := GetAllowance(g, "owner", uuid)
	assert.NoError(t, err)

	assert.Equal(t, initAllowance, postAllowance)
}

func TestSetZeroApprovalRemoves(t *testing.T) {
	g := gwtf.NewGoWithTheFlow("../../../flow.json")

	uuid, err := util.GetVaultUUID(g, "allowance")
	assert.NoError(t, err)

	err = Approve(g, "owner", uuid, "0.0")
	assert.NoError(t, err)

	_, err = GetAllowance(g, "owner", uuid)
	assert.Error(t, err)
}

func TestIncreaseAllowance(t *testing.T) {
	g := gwtf.NewGoWithTheFlow("../../../flow.json")

	uuid, err := util.GetVaultUUID(g, "allowance")
	assert.NoError(t, err)

	err = Approve(g, "owner", uuid, "10.0")
	assert.NoError(t, err)

	initAllowance, err := GetAllowance(g, "owner", uuid)
	assert.NoError(t, err)
	assert.Equal(t, "10.00000000", initAllowance.String())

	err = IncreaseOrDecreaseAlowance(g, "owner", uuid, "10.0", 1)
	assert.NoError(t, err)

	postAllowance, err := GetAllowance(g, "owner", uuid)
	assert.NoError(t, err)
	assert.Equal(t, "10.00000000", (postAllowance - initAllowance).String())
}

func TestDecreaseAllowance(t *testing.T) {
	g := gwtf.NewGoWithTheFlow("../../../flow.json")

	uuid, err := util.GetVaultUUID(g, "allowance")
	assert.NoError(t, err)

	err = Approve(g, "owner", uuid, "10.0")
	assert.NoError(t, err)

	initAllowance, err := GetAllowance(g, "owner", uuid)
	assert.NoError(t, err)

	err = IncreaseOrDecreaseAlowance(g, "owner", uuid, "3.0", 0)
	assert.NoError(t, err)

	postAllowance, err := GetAllowance(g, "owner", uuid)
	assert.NoError(t, err)
	assert.Equal(t, "3.00000000", (initAllowance - postAllowance).String())
}
