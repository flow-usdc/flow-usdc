package pause

import (
	"testing"

	"github.com/flow-usdc/flow-usdc/vault"
	"github.com/stretchr/testify/assert"
	"github.com/bjartek/go-with-the-flow/gwtf"
)

func TestCreatePauser(t *testing.T) {
	g := gwtf.NewGoWithTheFlow("../../../flow.json")
	err := CreatePauser(g, "pauser")
	assert.NoError(t, err)
}

func TestSetPauserCapability(t *testing.T) {
	g := gwtf.NewGoWithTheFlow("../../../flow.json")
	err := SetPauserCapability(g, "pauser", "owner")
	assert.NoError(t, err)
}

func TestPauserContractWithCap(t *testing.T) {
	g := gwtf.NewGoWithTheFlow("../../../flow.json")

	err := PauseOrUnpauseContract(g, "pauser", 1)
	assert.NoError(t, err)

	paused, pauseerr := GetPaused(g)
	assert.NoError(t, pauseerr)
	assert.Equal(t, paused.String(), "true")

	err = vault.AddVaultToAccount(g, "vaulted-account")
	assert.NoError(t, err)

	err = vault.TransferTokens(g, "100.0", "owner", "vaulted-account")
	assert.Error(t, err)
}

func TestPauserContractWithoutCap(t *testing.T) {
	g := gwtf.NewGoWithTheFlow("../../../flow.json")
	err := CreatePauser(g, "non-pauser")
	assert.NoError(t, err)

	pauseErr := PauseOrUnpauseContract(g, "non-pauser", 1)
	assert.Error(t, pauseErr)
}

func TestUnPauserContractWithCap(t *testing.T) {
	g := gwtf.NewGoWithTheFlow("../../../flow.json")
	err := PauseOrUnpauseContract(g, "pauser", 0)
	assert.NoError(t, err)

	paused, pauseerr := GetPaused(g)
	assert.NoError(t, pauseerr)
	assert.Equal(t, paused.String(), "false")

	err = vault.AddVaultToAccount(g, "vaulted-account")
	assert.NoError(t, err)

	err = vault.TransferTokens(g, "100.0", "owner", "vaulted-account")
    assert.NoError(t, err)
}
