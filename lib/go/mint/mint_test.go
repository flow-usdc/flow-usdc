package mint

import (
	"testing"

	"github.com/bjartek/go-with-the-flow/gwtf"
	"github.com/flow-usdc/flow-usdc/owner"
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

func TestRemoveMinterController(t *testing.T) {
	g := gwtf.NewGoWithTheFlow("../../../flow.json")
	minterController, err := GetMinterControllerUUID(g, "minterController1")
	assert.NoError(t, err)

	err = owner.RemoveMinterController(g, minterController, "owner")
	assert.NoError(t, err)

	_, err = GetManagedMinter(g, minterController)
	assert.Error(t, err)
}
