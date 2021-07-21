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

	events, err := AddVaultToAccount(g, "vaulted-account")
	assert.NoError(t, err)

	balance, err := util.GetBalance(g, "vaulted-account")
	assert.NoError(t, err)
	assert.Equal(t, balance.String(), "0.00000000")

	// Test event
	util.NewExpectedEvent("NewVault").AssertHasKey(t, events[0], "resourceId")
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
	events, err := TransferTokens(g, transferAmount, "owner", "vaulted-account")
	assert.NoError(t, err)

	balanceA, err := util.GetBalance(g, "vaulted-account")
	assert.NoError(t, err)
	assert.Equal(t, transferAmount, balanceA.String())

	// Test events
	uuid, err := util.GetVaultUUID(g, "owner")
	assert.NoError(t, err)
	util.NewExpectedEvent("FiatTokenWithdrawn").
		AddField("amount", transferAmount).
		AddField("from", strconv.Itoa(int(uuid))).
		AssertEqual(t, events[0])

	fromAddr := util.GetAccountAddr(g, "owner")
	util.NewExpectedEvent("TokensWithdrawn").
		AddField("amount", transferAmount).
		AddField("from", fromAddr).
		AssertEqual(t, events[1])

	uuid, err = util.GetVaultUUID(g, "vaulted-account")
	assert.NoError(t, err)
	util.NewExpectedEvent("FiatTokenDeposited").
		AddField("amount", transferAmount).
		AddField("to", strconv.Itoa(int(uuid))).
		AssertEqual(t, events[2])

	toAddr := util.GetAccountAddr(g, "vaulted-account")
	util.NewExpectedEvent("TokensDeposited").
		AddField("amount", transferAmount).
		AddField("to", toAddr).
		AssertEqual(t, events[3])

	util.NewExpectedEvent("DestroyVault").AssertHasKey(t, events[4], "resourceId")

	// Transfer the 100 token back from account A to FT minter
	_, err = TransferTokens(g, "100.00000000", "vaulted-account", "owner")
	assert.NoError(t, err)

	finalBalance, err := util.GetBalance(g, "owner")
	assert.NoError(t, err)
	assert.Equal(t, finalBalance, initialBalance)
}

func TestTransferToNonVaulted(t *testing.T) {
	g := gwtf.NewGoWithTheFlow("../../../flow.json")
	// Transfer 1 token from FT minter to Account B, which has no vault
	rawEvents, err := TransferTokens(g, "1000.00000000", "owner", "non-vaulted-account")
	assert.Error(t, err)
	assert.Empty(t, rawEvents)
}
