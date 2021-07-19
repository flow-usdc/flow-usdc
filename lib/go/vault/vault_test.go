package vault

import (
	"strconv"
	"testing"

	"github.com/bjartek/go-with-the-flow/gwtf"
	util "github.com/flow-usdc/flow-usdc"
	"github.com/stretchr/testify/assert"
)

func TestAddVaultToAccount(t *testing.T) {
	g := gwtf.NewGoWithTheFlow("../../../flow.json")

	rawEvents, err := AddVaultToAccount(g, "vaulted-account")
	assert.NoError(t, err)

	balance, err := util.GetBalance(g, "vaulted-account")
	assert.NoError(t, err)
	assert.Equal(t, balance.String(), "0.00000000")

	// Test event
	event := util.ParseTestEvent(rawEvents[0])
	util.NewExpectedEvent("NewVault").AssertHasKey(t, event, "resourceId")
}

func TestNonVaultedAccount(t *testing.T) {
	g := gwtf.NewGoWithTheFlow("../../../flow.json")

	_, err := util.GetBalance(g, "non-vaulted-account")
	assert.Error(t, err)
}

func TestTransferTokens(t *testing.T) {
	g := gwtf.NewGoWithTheFlow("../../../flow.json")

	initialBalance, err := util.GetBalance(g, "owner")
	assert.NoError(t, err)

	transferAmount := "100.00000000"
	rawEvents, err := TransferTokens(g, transferAmount, "owner", "vaulted-account")
	assert.NoError(t, err)

	balanceA, err := util.GetBalance(g, "vaulted-account")
	assert.NoError(t, err)
	assert.Equal(t, transferAmount, balanceA.String())

	// Print a formatted version of the event for more info
	gwtf.PrintEvents(rawEvents, map[string][]string{})

	// Test events
	event0 := util.ParseTestEvent(rawEvents[0])
	uuid, err := util.GetVaultUUID(g, "owner")
	assert.NoError(t, err)
	util.NewExpectedEvent("FiatTokenWithdrawn").
		AddField("amount", transferAmount).
		AddField("from", strconv.Itoa(int(uuid))).
		AssertEqual(t, event0)

	event1 := util.ParseTestEvent(rawEvents[1])
	fromAddr := util.GetAccountAddr(g, "owner")
	util.NewExpectedEvent("TokensWithdrawn").
		AddField("amount", transferAmount).
		AddField("from", fromAddr).
		AssertEqual(t, event1)

	event2 := util.ParseTestEvent(rawEvents[2])
	uuid, err = util.GetVaultUUID(g, "vaulted-account")
	assert.NoError(t, err)
	util.NewExpectedEvent("FiatTokenDeposited").
		AddField("amount", transferAmount).
		AddField("to", strconv.Itoa(int(uuid))).
		AssertEqual(t, event2)

	event3 := util.ParseTestEvent(rawEvents[3])
	toAddr := util.GetAccountAddr(g, "vaulted-account")
	util.NewExpectedEvent("TokensDeposited").
		AddField("amount", transferAmount).
		AddField("to", toAddr).
		AssertEqual(t, event3)

	event4 := util.ParseTestEvent(rawEvents[4])
	util.NewExpectedEvent("DestroyVault").AssertHasKey(t, event4, "resourceId")

	// Transfer the 100 token back from account A to FT minter
	_, err = TransferTokens(g, "100.0", "vaulted-account", "owner")
	assert.NoError(t, err)

	finalBalance, err := util.GetBalance(g, "owner")
	assert.NoError(t, err)
	assert.Equal(t, finalBalance, initialBalance)
}

func TestTransferToNonVaulted(t *testing.T) {
	g := gwtf.NewGoWithTheFlow("../../../flow.json")
	// Transfer 1 token from FT minter to Account B, which has no vault
	rawEvents, err := TransferTokens(g, "1000.0", "owner", "non-vaulted-account")
	assert.Error(t, err)

	// Test event
	assert.Empty(t, rawEvents)
}
