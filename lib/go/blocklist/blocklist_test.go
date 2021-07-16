package blocklist

import (
	"strconv"
	"testing"

	"github.com/bjartek/go-with-the-flow/gwtf"
	util "github.com/flow-usdc/flow-usdc"
	"github.com/flow-usdc/flow-usdc/owner"
	"github.com/flow-usdc/flow-usdc/vault"
	"github.com/stretchr/testify/assert"
)

func TestGetUUID(t *testing.T) {
	g := gwtf.NewGoWithTheFlow("../../../flow.json")

	err := vault.AddVaultToAccount(g, "vaulted-account")
	assert.NoError(t, err)

	_, err = util.GetVaultUUID(g, "vaulted-account")
	assert.NoError(t, err)
}

func TestCreateBlocklister(t *testing.T) {
	g := gwtf.NewGoWithTheFlow("../../../flow.json")
	rawEvents, err := CreateBlocklister(g, "blocklister")
	assert.NoError(t, err)

	// Test event
	event := util.ParseTestEvent(rawEvents[0])
	util.NewExpectedEvent("BlocklisterCreated").AssertHasKey(t, event, "resourceId")

	_, err = CreateBlocklister(g, "non-blocklister")
	assert.NoError(t, err)
}

func TestSetBlocklistCapability(t *testing.T) {
	g := gwtf.NewGoWithTheFlow("../../../flow.json")
	err := owner.SetBlocklistCapability(g, "blocklister", "owner")
	assert.NoError(t, err)
}

func TestBlocklistWithCap(t *testing.T) {
	g := gwtf.NewGoWithTheFlow("../../../flow.json")

	uuid, err := util.GetVaultUUID(g, "vaulted-account")
	assert.NoError(t, err)

	rawEvents, err := BlocklistOrUnblocklistRsc(g, "blocklister", uuid, 1)
	assert.NoError(t, err)

	// Test event
	event := util.ParseTestEvent(rawEvents[0])
	util.NewExpectedEvent("Blocklisted").AddField("resourceId", strconv.Itoa(int(uuid))).AssertEqual(t, event)

	blockheight, err := GetBlocklistStatus(g, uuid)
	assert.NoError(t, err)
	assert.Equal(t, true, blockheight > 0)

	// Once blocklisted, "vaulted-account" should not be able to transfer
	// - check initial and post tx balance is the same
	// - ensure that tx fails

	init_rec_balance, err := util.GetBalance(g, "vaulted-account")
	assert.NoError(t, err)

	_, err = vault.TransferTokens(g, "10.0", "owner", "vaulted-account")
	assert.Error(t, err)

	post_rec_balance, err := util.GetBalance(g, "vaulted-account")
	assert.NoError(t, err)

	assert.Equal(t, init_rec_balance, post_rec_balance)
}

func TestUnblocklistWithCap(t *testing.T) {
	g := gwtf.NewGoWithTheFlow("../../../flow.json")

	uuid, err := util.GetVaultUUID(g, "vaulted-account")
	assert.NoError(t, err)

	rawEvents, err := BlocklistOrUnblocklistRsc(g, "blocklister", uuid, 0)
	assert.NoError(t, err)

	// Test event
	event := util.ParseTestEvent(rawEvents[0])
	util.NewExpectedEvent("Unblocklisted").AddField("resourceId", strconv.Itoa(int(uuid))).AssertEqual(t, event)

	// After blocklisted, "vaulted-account" should be able to transfer
	// - the balance of post tx, recv should receive 10.0 more
	// - ensure that tx has no error

	init_rec_balance, err := util.GetBalance(g, "vaulted-account")
	assert.NoError(t, err)

	_, err = vault.TransferTokens(g, "10.0", "owner", "vaulted-account")
	assert.NoError(t, err)

	post_rec_balance, err := util.GetBalance(g, "vaulted-account")
	assert.NoError(t, err)

	assert.Equal(t, "10.00000000", (post_rec_balance - init_rec_balance).String())
}

func TestBlocklistWithoutCap(t *testing.T) {
	g := gwtf.NewGoWithTheFlow("../../../flow.json")

	uuid, err := util.GetVaultUUID(g, "vaulted-account")
	assert.NoError(t, err)

	_, err = BlocklistOrUnblocklistRsc(g, "non-blocklister", uuid, 1)
	assert.Error(t, err)
}
