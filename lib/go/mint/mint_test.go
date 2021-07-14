package mint

import (
	"testing"

	"github.com/bjartek/go-with-the-flow/gwtf"
	util "github.com/flow-usdc/flow-usdc"
	"github.com/flow-usdc/flow-usdc/owner"
	"github.com/flow-usdc/flow-usdc/vault"
	"github.com/onflow/cadence"
	"github.com/stretchr/testify/assert"
)

func TestCreateMinter(t *testing.T) {
	g := gwtf.NewGoWithTheFlow("../../../flow.json")
	err := CreateMinter(g, "minter")
	assert.NoError(t, err)

	_, err = GetMinterUUID(g, "minter")
	assert.NoError(t, err)
}

func TestCreateMinterController(t *testing.T) {
	g := gwtf.NewGoWithTheFlow("../../../flow.json")
	err := CreateMinterController(g, "minterController1")
	assert.NoError(t, err)

	_, err = GetMinterControllerUUID(g, "minterController1")
	assert.NoError(t, err)
}

func TestConfigureMinterController(t *testing.T) {
	g := gwtf.NewGoWithTheFlow("../../../flow.json")

	minterController, err := GetMinterControllerUUID(g, "minterController1")
	assert.NoError(t, err)

	minter, err := GetMinterUUID(g, "minter")
	assert.NoError(t, err)

	err = owner.ConfigureMinterController(g, minterController, minter, "owner")
	assert.NoError(t, err)

	managedMinter, err := GetManagedMinter(g, minterController)
	assert.NoError(t, err)
	assert.Equal(t, minter, managedMinter)
}

func TestConfigureMinterAllowance(t *testing.T) {
	g := gwtf.NewGoWithTheFlow("../../../flow.json")

	minter, err := GetMinterUUID(g, "minter")
	assert.NoError(t, err)

	var allowanceInput = "500.0"
	err = ConfigureMinterAllowance(g, "minterController1", allowanceInput)
	assert.NoError(t, err)

	allowance, err := GetMinterAllowance(g, minter)
	assert.NoError(t, err)
	expected, err := cadence.NewUFix64(allowanceInput)
	assert.NoError(t, err)
	assert.Equal(t, expected, allowance)
}

func TestMintWithAllowace(t *testing.T) {
	g := gwtf.NewGoWithTheFlow("../../../flow.json")

	// Params
	err := vault.AddVaultToAccount(g, "minter")
	assert.NoError(t, err)
	minter, err := GetMinterUUID(g, "minter")
	assert.NoError(t, err)
	mintAmountStr := "200.0"
	mintAmount, err := cadence.NewUFix64(mintAmountStr)
	assert.NoError(t, err)

	// Initial values
	initTotalSupply, err := util.GetTotalSupply(g)
	assert.NoError(t, err)
	initBalance, err := util.GetBalance(g, "minter")
	assert.NoError(t, err)
	initMintAllowance, err := GetMinterAllowance(g, minter)
	assert.NoError(t, err)

	// Execute mint
	err = Mint(g, "minter", mintAmountStr, "minter")
	assert.NoError(t, err)

	// Post mint values
	postTotalSupply, err := util.GetTotalSupply(g)
	assert.NoError(t, err)
	postBalance, err := util.GetBalance(g, "minter")
	assert.NoError(t, err)
	postMintAllowance, err := GetMinterAllowance(g, minter)
	assert.NoError(t, err)

	// Assertions
	assert.Equal(t, mintAmount, postTotalSupply-initTotalSupply)
	assert.Equal(t, mintAmount, postBalance-initBalance)
	assert.Equal(t, mintAmount, initMintAllowance-postMintAllowance)
}

func TestRemoveMinterController(t *testing.T) {
	g := gwtf.NewGoWithTheFlow("../../../flow.json")
	minterController, err := GetMinterControllerUUID(g, "minterController1")
	assert.NoError(t, err)

	err = owner.RemoveMinterController(g, minterController, "owner")
	assert.NoError(t, err)

	_, err = GetManagedMinter(g, minterController)
	assert.Error(t, err)
}
