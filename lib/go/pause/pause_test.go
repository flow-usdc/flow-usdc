package pause

import (
	"testing"

	"github.com/bjartek/go-with-the-flow/gwtf"
	util "github.com/flow-usdc/flow-usdc"
	"github.com/flow-usdc/flow-usdc/owner"
	"github.com/flow-usdc/flow-usdc/vault"

	"github.com/stretchr/testify/assert"
)

func TestCreatePauser(t *testing.T) {
	g := gwtf.NewGoWithTheFlow("../../../flow.json")

	rawEvents, err := CreatePauser(g, "pauser")
	assert.NoError(t, err)

	// Test event
	event := util.ParseTestEvent(rawEvents[0])
	util.NewExpectedEvent("PauserCreated").AssertHasKey(t, event, "resourceId")
}

func TestSetPauserCapability(t *testing.T) {
	g := gwtf.NewGoWithTheFlow("../../../flow.json")
	err := owner.SetPauserCapability(g, "pauser", "owner")
	assert.NoError(t, err)
}

func TestPauserContractWithCap(t *testing.T) {
	g := gwtf.NewGoWithTheFlow("../../../flow.json")

	rawEvents, err := PauseOrUnpauseContract(g, "pauser", 1)
	assert.NoError(t, err)

	// Test contract pause state
	paused, pauseerr := GetPaused(g)
	assert.NoError(t, pauseerr)
	assert.Equal(t, paused.String(), "true")

	// Test event
	event := util.ParseTestEvent(rawEvents[0])
	util.NewExpectedEvent("Paused").AssertEqual(t, event)

	_, err = vault.AddVaultToAccount(g, "vaulted-account")
	assert.NoError(t, err)

	_, err = vault.TransferTokens(g, "100.0", "owner", "vaulted-account")
	assert.Error(t, err)
}

func TestPauserContractWithoutCap(t *testing.T) {
	g := gwtf.NewGoWithTheFlow("../../../flow.json")
	_, err := CreatePauser(g, "non-pauser")
	assert.NoError(t, err)

	_, pauseErr := PauseOrUnpauseContract(g, "non-pauser", 1)
	assert.Error(t, pauseErr)
}

func TestUnPauserContractWithCap(t *testing.T) {
	g := gwtf.NewGoWithTheFlow("../../../flow.json")
	rawEvents, err := PauseOrUnpauseContract(g, "pauser", 0)
	assert.NoError(t, err)

	// Test contract pause state
	paused, pauseerr := GetPaused(g)
	assert.NoError(t, pauseerr)
	assert.Equal(t, paused.String(), "false")

	// Test event
	event := util.ParseTestEvent(rawEvents[0])
	util.NewExpectedEvent("Unpaused").AssertEqual(t, event)

	_, err = vault.AddVaultToAccount(g, "vaulted-account")
	assert.NoError(t, err)

	_, err = vault.TransferTokens(g, "100.0", "owner", "vaulted-account")
	assert.NoError(t, err)
}
