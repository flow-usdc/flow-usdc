package vault

import (
	"os"
	"strconv"
	"testing"

	"github.com/bjartek/go-with-the-flow/v2/gwtf"
	util "github.com/flow-usdc/flow-usdc"
	"github.com/stretchr/testify/assert"
)

func TestAddVaultToAccount(t *testing.T) {
	g := gwtf.NewGoWithTheFlow(util.FlowJSON, os.Getenv("NETWORK"), false, 1)

	events, err := AddVaultToAccount(g, "vaulted-account")
	assert.NoError(t, err)

	_, err = util.GetBalance(g, "vaulted-account")
	assert.NoError(t, err)

	// Test event, the first events on testnet will be withdrawing for fees
	// regardless if a new vault is created therefore we only test on emulator
	if len(events) != 0 && g.Network == "emulator" {
		util.NewExpectedEvent("FiatToken", "NewVault").AssertHasKey(t, events[0], "resourceId")
	}
}

func TestNonVaultedAccount(t *testing.T) {
	g := gwtf.NewGoWithTheFlow(util.FlowJSON, os.Getenv("NETWORK"), false, 1)

	_, err := util.GetBalance(g, "non-vaulted-account")
	assert.Error(t, err)
}

func TestTransferTokens(t *testing.T) {
	g := gwtf.NewGoWithTheFlow(util.FlowJSON, os.Getenv("NETWORK"), false, 1)

	initialBalance, err := util.GetBalance(g, "owner")
	assert.NoError(t, err)
	initRecvBalance, err := util.GetBalance(g, "vaulted-account")
	assert.NoError(t, err)

	transferAmount := "100.00000000"
	events, err := TransferTokens(g, transferAmount, "owner", "vaulted-account")
	assert.NoError(t, err)

	postRecvBalance, err := util.GetBalance(g, "vaulted-account")
	assert.NoError(t, err)
	assert.Equal(t, transferAmount, (postRecvBalance - initRecvBalance).String())

	// Test events
	uuid, err := util.GetUUID(g, "owner", "Vault")
	assert.NoError(t, err)
	util.NewExpectedEvent("FiatToken", "FiatTokenWithdrawn").
		AddField("amount", transferAmount).
		AddField("from", strconv.Itoa(int(uuid))).
		AssertEqual(t, events[0])

	fromAddr := util.GetAccountAddr(g, "owner")
	util.NewExpectedEvent("FiatToken", "TokensWithdrawn").
		AddField("amount", transferAmount).
		AddField("from", fromAddr).
		AssertEqual(t, events[1])

	uuid, err = util.GetUUID(g, "vaulted-account", "Vault")
	assert.NoError(t, err)
	util.NewExpectedEvent("FiatToken", "FiatTokenDeposited").
		AddField("amount", transferAmount).
		AddField("to", strconv.Itoa(int(uuid))).
		AssertEqual(t, events[2])

	toAddr := util.GetAccountAddr(g, "vaulted-account")
	util.NewExpectedEvent("FiatToken", "TokensDeposited").
		AddField("amount", transferAmount).
		AddField("to", toAddr).
		AssertEqual(t, events[3])

	util.NewExpectedEvent("FiatToken", "DestroyVault").AssertHasKey(t, events[4], "resourceId")

	// Transfer the 100 token back from vaulted-account to owner
	_, err = TransferTokens(g, "100.00000000", "vaulted-account", "owner")
	assert.NoError(t, err)

	finalBalance, err := util.GetBalance(g, "owner")
	assert.NoError(t, err)
	assert.Equal(t, finalBalance, initialBalance)
}

func TestTransferToNonVaulted(t *testing.T) {
	g := gwtf.NewGoWithTheFlow(util.FlowJSON, os.Getenv("NETWORK"), false, 1)
	// Transfer 1 token from FT vaulted-account to Account B, which has no vault
	rawEvents, err := TransferTokens(g, "1000.00000000", "owner", "non-vaulted-account")
	assert.Error(t, err)
	assert.Empty(t, rawEvents)
}
