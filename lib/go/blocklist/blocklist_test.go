package blocklist

import (
	"os"
	"strconv"
	"testing"

	"github.com/bjartek/go-with-the-flow/v2/gwtf"
	util "github.com/flow-usdc/flow-usdc"
	"github.com/flow-usdc/flow-usdc/owner"
	"github.com/flow-usdc/flow-usdc/vault"
	"github.com/stretchr/testify/assert"
)

func TestCreateBlocklister(t *testing.T) {
	g := gwtf.NewGoWithTheFlow(util.FlowJSON, os.Getenv("NETWORK"), false, 1)
	events, err := CreateBlocklister(g, "blocklister")
	assert.NoError(t, err)

	// Test event
	util.NewExpectedEvent("FiatToken", "BlocklisterCreated").AssertHasKey(t, events[0], "resourceId")

	_, err = CreateBlocklister(g, "non-blocklister")
	assert.NoError(t, err)
}

func TestSetBlocklistCapability(t *testing.T) {
	g := gwtf.NewGoWithTheFlow(util.FlowJSON, os.Getenv("NETWORK"), false, 1)
	err := owner.SetBlocklistCapability(g, "blocklister", "owner")
	assert.NoError(t, err)
}

func TestBlocklistWithCap(t *testing.T) {
	g := gwtf.NewGoWithTheFlow(util.FlowJSON, os.Getenv("NETWORK"), false, 1)

	_, err := vault.AddVaultToAccount(g, "vaulted-account")
	assert.NoError(t, err)

	_, err = vault.TransferTokens(g, "1.00000000", "owner", "vaulted-account")
	assert.NoError(t, err)

	uuid, err := util.GetUUID(g, "vaulted-account", "Vault")
	assert.NoError(t, err)

	events, err := BlocklistOrUnblocklistRsc(g, "blocklister", uuid, 1)
	assert.NoError(t, err)

	// Test event
	util.NewExpectedEvent("FiatToken", "Blocklisted").AddField("resourceId", strconv.Itoa(int(uuid))).AssertEqual(t, events[0])

	blockheight, err := GetBlocklistStatus(g, uuid)
	assert.NoError(t, err)
	assert.Equal(t, true, blockheight > 0)

	// Once blocklisted, "vaulted-account" should not be able to transfer / recv / load
	// its vault and deposit its content into another vault
	// - check initial and post tx balance is the same
	// - ensure that tx fails

	init_rec_balance, err := util.GetBalance(g, "vaulted-account")
	assert.NoError(t, err)

	// Test cannot receive
	events, err = vault.TransferTokens(g, "10.00000000", "owner", "vaulted-account")
	assert.Error(t, err)
	assert.Empty(t, events)

	// Test cannot withdraw
	events, err = vault.TransferTokens(g, "0.50000000", "vaulted-account", "owner")
	assert.Error(t, err)
	assert.Empty(t, events)

	// Test cannot load and deposit
	events, err = vault.MoveAndDeposit(g, "vaulted-account", "owner")
	assert.Error(t, err)
	assert.Empty(t, events)

	post_rec_balance, err := util.GetBalance(g, "vaulted-account")
	assert.NoError(t, err)

	assert.Equal(t, init_rec_balance, post_rec_balance)
}

func TestUnblocklistWithCap(t *testing.T) {
	g := gwtf.NewGoWithTheFlow(util.FlowJSON, os.Getenv("NETWORK"), false, 1)

	uuid, err := util.GetUUID(g, "vaulted-account", "Vault")
	assert.NoError(t, err)

	events, err := BlocklistOrUnblocklistRsc(g, "blocklister", uuid, 0)
	assert.NoError(t, err)

	// Test event
	util.NewExpectedEvent("FiatToken", "Unblocklisted").AddField("resourceId", strconv.Itoa(int(uuid))).AssertEqual(t, events[0])

	// After blocklisted, "vaulted-account" should be able to transfer
	// - the balance of post tx, recv should receive 10.0 more
	// - ensure that tx has no error

	init_rec_balance, err := util.GetBalance(g, "vaulted-account")
	assert.NoError(t, err)

	_, err = vault.TransferTokens(g, "10.00000000", "owner", "vaulted-account")
	assert.NoError(t, err)

	post_rec_balance, err := util.GetBalance(g, "vaulted-account")
	assert.NoError(t, err)

	assert.Equal(t, "10.00000000", (post_rec_balance - init_rec_balance).String())
}

func TestBlocklistWithoutCap(t *testing.T) {
	g := gwtf.NewGoWithTheFlow(util.FlowJSON, os.Getenv("NETWORK"), false, 1)

	uuid, err := util.GetUUID(g, "vaulted-account", "Vault")
	assert.NoError(t, err)

	rawEvents, err := BlocklistOrUnblocklistRsc(g, "non-blocklister", uuid, 1)
	assert.Error(t, err)
	assert.Empty(t, rawEvents)
}

func TestMultiSig_Blocklist(t *testing.T) {
	g := gwtf.NewGoWithTheFlow(util.FlowJSON, os.Getenv("NETWORK"), false, 1)

	// Add New Payload
	currentIndex, err := util.GetTxIndex(g, "blocklister", "Blocklister")
	assert.NoError(t, err)
	expectedNewIndex := currentIndex + 1

	toBlock := uint64(111)
	resourceId := util.Arg{V: toBlock, T: "UInt64"}

	// `true` for new payload
	events, err := util.MultiSig_SignAndSubmit(g, true, expectedNewIndex, util.Acct500_1, "blocklister", "Blocklister", "blocklist", resourceId)
	assert.NoError(t, err)

	newTxIndex, err := util.GetTxIndex(g, "blocklister", "Blocklister")
	assert.NoError(t, err)
	assert.Equal(t, expectedNewIndex, newTxIndex)

	blocklister, err := util.GetUUID(g, "blocklister", "Blocklister")
	assert.NoError(t, err)

	util.NewExpectedEvent("OnChainMultiSig", "NewPayloadAdded").
		AddField("resourceId", strconv.Itoa(int(blocklister))).
		AddField("txIndex", strconv.Itoa(int(newTxIndex))).
		AssertEqual(t, events[0])

	// Try to Execute without enough weight. This should error as there is not enough signer yet
	_, err = util.MultiSig_ExecuteTx(g, newTxIndex, "owner", "blocklister", "Blocklister")
	assert.Error(t, err)

	// Add Another Payload Signature
	// `false` for new signature for existing paylaod
	events, err = util.MultiSig_SignAndSubmit(g, false, expectedNewIndex, util.Acct500_2, "blocklister", "Blocklister", "blocklist", resourceId)
	assert.NoError(t, err)

	util.NewExpectedEvent("OnChainMultiSig", "NewPayloadSigAdded").
		AddField("resourceId", strconv.Itoa(int(blocklister))).
		AddField("txIndex", strconv.Itoa(int(newTxIndex))).
		AssertEqual(t, events[0])

	events, err = util.MultiSig_ExecuteTx(g, newTxIndex, "owner", "blocklister", "Blocklister")
	assert.NoError(t, err)

	// Test event
	util.NewExpectedEvent("FiatToken", "Blocklisted").AddField("resourceId", strconv.Itoa(int(toBlock))).AssertEqual(t, events[0])

	blockheight, err := GetBlocklistStatus(g, toBlock)
	assert.NoError(t, err)
	assert.Equal(t, true, blockheight > 0)
}

func TestMultiSig_Unblocklist(t *testing.T) {
	g := gwtf.NewGoWithTheFlow(util.FlowJSON, os.Getenv("NETWORK"), false, 1)

	// Add New Payload
	currentIndex, err := util.GetTxIndex(g, "blocklister", "Blocklister")
	assert.NoError(t, err)
	expectedNewIndex := currentIndex + 1

	toUnblock := uint64(111)
	resourceId := util.Arg{V: toUnblock, T: "UInt64"}

	// `true` for new payload
	// signed with full account
	_, err = util.MultiSig_SignAndSubmit(g, true, expectedNewIndex, util.Acct1000, "blocklister", "Blocklister", "unblocklist", resourceId)
	assert.NoError(t, err)

	newTxIndex, err := util.GetTxIndex(g, "blocklister", "Blocklister")
	assert.NoError(t, err)
	assert.Equal(t, expectedNewIndex, newTxIndex)

	events, err := util.MultiSig_ExecuteTx(g, newTxIndex, "owner", "blocklister", "Blocklister")
	assert.NoError(t, err)

	// Test event
	util.NewExpectedEvent("FiatToken", "Unblocklisted").AddField("resourceId", strconv.Itoa(int(toUnblock))).AssertEqual(t, events[0])

	blocked, err := GetBlocklistStatus(g, toUnblock)
	assert.NoError(t, err)
	assert.Equal(t, uint64(0), blocked)
}

func TestMultiSig_BlocklisterUnknowMethodFails(t *testing.T) {
	g := gwtf.NewGoWithTheFlow(util.FlowJSON, os.Getenv("NETWORK"), false, 1)

	m := util.Arg{V: uint64(111), T: "UInt64"}

	txIndex, err := util.GetTxIndex(g, "blocklister", "Blocklister")
	assert.NoError(t, err)

	_, err = util.MultiSig_SignAndSubmit(g, true, txIndex+1, util.Acct1000, "blocklister", "Blocklister", "unknowmethod", m)
	assert.NoError(t, err)

	newTxIndex, err := util.GetTxIndex(g, "blocklister", "Blocklister")
	assert.NoError(t, err)

	_, err = util.MultiSig_ExecuteTx(g, newTxIndex, "owner", "blocklister", "Blocklister")
	assert.Error(t, err)
}

func TestMultiSig_BlocklisterCanRemoveKey(t *testing.T) {
	g := gwtf.NewGoWithTheFlow(util.FlowJSON, os.Getenv("NETWORK"), false, 1)

	pk250_1 := g.Account(util.Acct250_1).Key().ToConfig().PrivateKey.PublicKey().String()
	k := util.Arg{V: pk250_1[2:], T: "String"}

	hasKey, err := util.ContainsKey(g, "blocklister", "Blocklister", pk250_1[2:])
	assert.NoError(t, err)
	assert.Equal(t, hasKey, true)

	txIndex, err := util.GetTxIndex(g, "blocklister", "Blocklister")
	newTxIndex := txIndex + 1
	assert.NoError(t, err)

	_, err = util.MultiSig_SignAndSubmit(g, true, newTxIndex, util.Acct1000, "blocklister", "Blocklister", "removeKey", k)
	assert.NoError(t, err)

	_, err = util.MultiSig_ExecuteTx(g, newTxIndex, "owner", "blocklister", "Blocklister")
	assert.NoError(t, err)

	hasKey, err = util.ContainsKey(g, "blocklister", "Blocklister", pk250_1[2:])
	assert.NoError(t, err)
	assert.Equal(t, hasKey, false)
}

func TestMultiSig_BlocklisterCanAddKey(t *testing.T) {
	g := gwtf.NewGoWithTheFlow(util.FlowJSON, os.Getenv("NETWORK"), false, 1)

	pk250_1 := g.Account(util.Acct250_1).Key().ToConfig().PrivateKey.PublicKey().String()
	k := util.Arg{V: pk250_1[2:], T: "String"}
	w := util.Arg{V: "250.00000000", T: "UFix64"}
	sa := util.Arg{V: uint8(1), T: "UInt8"}

	hasKey, err := util.ContainsKey(g, "blocklister", "Blocklister", pk250_1[2:])
	assert.NoError(t, err)
	assert.Equal(t, hasKey, false)

	txIndex, err := util.GetTxIndex(g, "blocklister", "Blocklister")
	newTxIndex := txIndex + 1
	assert.NoError(t, err)

	_, err = util.MultiSig_SignAndSubmit(g, true, newTxIndex, util.Acct1000, "blocklister", "Blocklister", "configureKey", k, w, sa)
	assert.NoError(t, err)

	_, err = util.MultiSig_ExecuteTx(g, newTxIndex, "owner", "blocklister", "Blocklister")
	assert.NoError(t, err)

	hasKey, err = util.ContainsKey(g, "blocklister", "Blocklister", pk250_1[2:])
	assert.NoError(t, err)
	assert.Equal(t, hasKey, true)

	weight, err := util.GetKeyWeight(g, util.Acct250_1, "blocklister", "Blocklister")
	assert.NoError(t, err)
	assert.Equal(t, w.V, weight.String())
}
