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

	events, err := CreatePauser(g, "pauser")
	assert.NoError(t, err)

	// Test event
	util.NewExpectedEvent("FiatToken", "PauserCreated").AssertHasKey(t, events[0], "resourceId")
}

func TestSetPauserCapability(t *testing.T) {
	g := gwtf.NewGoWithTheFlow("../../../flow.json")
	err := owner.SetPauserCapability(g, "pauser", "owner")
	assert.NoError(t, err)
}

func TestPauserContractWithCap(t *testing.T) {
	g := gwtf.NewGoWithTheFlow("../../../flow.json")

	events, err := PauseOrUnpauseContract(g, "pauser", 1)
	assert.NoError(t, err)

	// Test contract pause state
	paused, pauseerr := GetPaused(g)
	assert.NoError(t, pauseerr)
	assert.Equal(t, paused.String(), "true")

	// Test event
	util.NewExpectedEvent("FiatToken", "Paused").AssertEqual(t, events[0])

	_, err = vault.AddVaultToAccount(g, "vaulted-account")
	assert.NoError(t, err)

	events, err = vault.TransferTokens(g, "100.00000000", "owner", "vaulted-account")
	assert.Error(t, err)
	assert.Empty(t, events)
}

func TestPauserContractWithoutCap(t *testing.T) {
	g := gwtf.NewGoWithTheFlow("../../../flow.json")
	_, err := CreatePauser(g, "non-pauser")
	assert.NoError(t, err)

	rawEvents, pauseErr := PauseOrUnpauseContract(g, "non-pauser", 1)
	assert.Error(t, pauseErr)
	assert.Empty(t, rawEvents)
}

func TestUnPauserContractWithCap(t *testing.T) {
	g := gwtf.NewGoWithTheFlow("../../../flow.json")
	events, err := PauseOrUnpauseContract(g, "pauser", 0)
	assert.NoError(t, err)

	// Test contract pause state
	paused, pauseerr := GetPaused(g)
	assert.NoError(t, pauseerr)
	assert.Equal(t, paused.String(), "false")

	// Test event
	util.NewExpectedEvent("FiatToken", "Unpaused").AssertEqual(t, events[0])

	_, err = vault.AddVaultToAccount(g, "vaulted-account")
	assert.NoError(t, err)

	_, err = vault.TransferTokens(g, "100.00000000", "owner", "vaulted-account")
	assert.NoError(t, err)
}
