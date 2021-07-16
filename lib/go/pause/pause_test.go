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
	// Print a formatted version of the event for more info
	gwtf.PrintEvents(rawEvents, map[string][]string{})

	// Test event
	event := util.ParseTestEvent(rawEvents[0])
	expectedEvent := util.NewExpectedEvent("PauserCreated")
	assert.Equal(t, event.Name, expectedEvent.Name)
	_, exist := event.Fields["resourceId"]
	assert.Equal(t, true, exist)
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
	expectedEvent := util.NewExpectedEvent("Paused")
	assert.Equal(t, event.Name, expectedEvent.Name)

	err = vault.AddVaultToAccount(g, "vaulted-account")
	assert.NoError(t, err)

	err = vault.TransferTokens(g, "100.0", "owner", "vaulted-account")
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
	expectedEvent := util.NewExpectedEvent("Unpaused")
	assert.Equal(t, event.Name, expectedEvent.Name)

	err = vault.AddVaultToAccount(g, "vaulted-account")
	assert.NoError(t, err)

	err = vault.TransferTokens(g, "100.0", "owner", "vaulted-account")
	assert.NoError(t, err)
}
