package pause

import (
	"strconv"
	"testing"

	"github.com/bjartek/go-with-the-flow/v2/gwtf"
	util "github.com/flow-usdc/flow-usdc"
	"github.com/flow-usdc/flow-usdc/owner"
	"github.com/flow-usdc/flow-usdc/vault"

	"os"

	"github.com/stretchr/testify/assert"
)

func TestCreatePauser(t *testing.T) {
	g := gwtf.NewGoWithTheFlow(util.FlowJSON, os.Getenv("NETWORK"), false, 1)

	events, err := CreatePauser(g, "pauser")
	assert.NoError(t, err)

	// Test event
	util.NewExpectedEvent("FiatToken", "PauserCreated").AssertHasKey(t, events[0], "resourceId")
}

func TestSetPauserCapability(t *testing.T) {
	g := gwtf.NewGoWithTheFlow(util.FlowJSON, os.Getenv("NETWORK"), false, 1)
	err := owner.SetPauserCapability(g, "pauser", "owner")
	assert.NoError(t, err)
}

func TestPauserContractWithCap(t *testing.T) {
	g := gwtf.NewGoWithTheFlow(util.FlowJSON, os.Getenv("NETWORK"), false, 1)

	events, err := PauseOrUnpauseContract(g, "pauser", 1)
	assert.NoError(t, err)

	// Test contract pause state
	paused, pauseerr := GetPaused(g)
	assert.NoError(t, pauseerr)
	assert.Equal(t, true, paused)

	// Test event
	util.NewExpectedEvent("FiatToken", "Paused").AssertEqual(t, events[0])

	_, err = vault.AddVaultToAccount(g, "vaulted-account")
	assert.NoError(t, err)

	events, err = vault.TransferTokens(g, "100.00000000", "owner", "vaulted-account")
	assert.Error(t, err)
	assert.Empty(t, events)
}

func TestPauserContractWithoutCap(t *testing.T) {
	g := gwtf.NewGoWithTheFlow(util.FlowJSON, os.Getenv("NETWORK"), false, 1)
	_, err := CreatePauser(g, "non-pauser")
	assert.NoError(t, err)

	rawEvents, pauseErr := PauseOrUnpauseContract(g, "non-pauser", 1)
	assert.Error(t, pauseErr)
	assert.Empty(t, rawEvents)
}

func TestUnPauserContractWithCap(t *testing.T) {
	g := gwtf.NewGoWithTheFlow(util.FlowJSON, os.Getenv("NETWORK"), false, 1)
	events, err := PauseOrUnpauseContract(g, "pauser", 0)
	assert.NoError(t, err)

	// Test contract pause state
	paused, pauseerr := GetPaused(g)
	assert.NoError(t, pauseerr)
	assert.Equal(t, false, paused)

	// Test event
	util.NewExpectedEvent("FiatToken", "Unpaused").AssertEqual(t, events[0])

	_, err = vault.AddVaultToAccount(g, "vaulted-account")
	assert.NoError(t, err)

	_, err = vault.TransferTokens(g, "100.00000000", "owner", "vaulted-account")
	assert.NoError(t, err)
}

func TestMultiSig_Pause(t *testing.T) {
	g := gwtf.NewGoWithTheFlow(util.FlowJSON, os.Getenv("NETWORK"), false, 1)

	// Add New Payload
	currentIndex, err := util.GetTxIndex(g, "pauser", "Pauser")
	assert.NoError(t, err)
	expectedNewIndex := currentIndex + 1

	// `true` for new payload
	events, err := util.MultiSig_SignAndSubmit(g, true, expectedNewIndex, util.Acct500_1, "pauser", "Pauser", "pause")
	assert.NoError(t, err)

	newTxIndex, err := util.GetTxIndex(g, "pauser", "Pauser")
	assert.NoError(t, err)
	assert.Equal(t, expectedNewIndex, newTxIndex)

	pauser, err := util.GetUUID(g, "pauser", "Pauser")
	assert.NoError(t, err)

	util.NewExpectedEvent("OnChainMultiSig", "NewPayloadAdded").
		AddField("resourceId", strconv.Itoa(int(pauser))).
		AddField("txIndex", strconv.Itoa(int(newTxIndex))).
		AssertEqual(t, events[0])

	// Try to Execute without enough weight. This should error as there is not enough signer yet
	_, err = util.MultiSig_ExecuteTx(g, newTxIndex, "owner", "pauser", "Pauser")
	assert.Error(t, err)

	// Add Another Payload Signature
	// `false` for new signature for existing paylaod
	events, err = util.MultiSig_SignAndSubmit(g, false, expectedNewIndex, util.Acct500_2, "pauser", "Pauser", "pause")
	assert.NoError(t, err)

	util.NewExpectedEvent("OnChainMultiSig", "NewPayloadSigAdded").
		AddField("resourceId", strconv.Itoa(int(pauser))).
		AddField("txIndex", strconv.Itoa(int(newTxIndex))).
		AssertEqual(t, events[0])

	events, err = util.MultiSig_ExecuteTx(g, newTxIndex, "owner", "pauser", "Pauser")
	assert.NoError(t, err)

	// Test event
	util.NewExpectedEvent("FiatToken", "Paused").AssertEqual(t, events[0])

	paused, err := GetPaused(g)
	assert.NoError(t, err)
	assert.Equal(t, true, paused)
}

func TestMultiSig_Unpause(t *testing.T) {
	g := gwtf.NewGoWithTheFlow(util.FlowJSON, os.Getenv("NETWORK"), false, 1)

	// Add New Payload
	currentIndex, err := util.GetTxIndex(g, "pauser", "Pauser")
	assert.NoError(t, err)
	expectedNewIndex := currentIndex + 1

	// `true` for new payload
	// signed with full account
	_, err = util.MultiSig_SignAndSubmit(g, true, expectedNewIndex, util.Acct1000, "pauser", "Pauser", "unpause")
	assert.NoError(t, err)

	newTxIndex, err := util.GetTxIndex(g, "pauser", "Pauser")
	assert.NoError(t, err)
	assert.Equal(t, expectedNewIndex, newTxIndex)

	events, err := util.MultiSig_ExecuteTx(g, newTxIndex, "owner", "pauser", "Pauser")
	assert.NoError(t, err)

	// Test event
	util.NewExpectedEvent("FiatToken", "Unpaused").AssertEqual(t, events[0])

	paused, err := GetPaused(g)
	assert.NoError(t, err)
	assert.Equal(t, false, paused)
}

func TestMultiSig_PauserUnknowMethodFails(t *testing.T) {
	g := gwtf.NewGoWithTheFlow(util.FlowJSON, os.Getenv("NETWORK"), false, 1)
	m := util.Arg{V: uint64(111), T: "UInt64"}

	txIndex, err := util.GetTxIndex(g, "pauser", "Pauser")
	assert.NoError(t, err)

	_, err = util.MultiSig_SignAndSubmit(g, true, txIndex+1, util.Acct1000, "pauser", "Pauser", "unknowmethod", m)
	assert.NoError(t, err)

	newTxIndex, err := util.GetTxIndex(g, "pauser", "Pauser")
	assert.NoError(t, err)

	_, err = util.MultiSig_ExecuteTx(g, newTxIndex, "owner", "pauser", "Pauser")
	assert.Error(t, err)
}

func TestMultiSig_PauserCanRemoveKey(t *testing.T) {
	g := gwtf.NewGoWithTheFlow(util.FlowJSON, os.Getenv("NETWORK"), false, 1)
	pk250_1 := g.Account(util.Acct250_1).Key().ToConfig().PrivateKey.PublicKey().String()
	k := util.Arg{V: pk250_1[2:], T: "String"}

	hasKey, err := util.ContainsKey(g, "pauser", "Pauser", pk250_1[2:])
	assert.NoError(t, err)
	assert.Equal(t, hasKey, true)

	txIndex, err := util.GetTxIndex(g, "pauser", "Pauser")
	newTxIndex := txIndex + 1
	assert.NoError(t, err)

	_, err = util.MultiSig_SignAndSubmit(g, true, newTxIndex, util.Acct1000, "pauser", "Pauser", "removeKey", k)
	assert.NoError(t, err)

	_, err = util.MultiSig_ExecuteTx(g, newTxIndex, "owner", "pauser", "Pauser")
	assert.NoError(t, err)

	hasKey, err = util.ContainsKey(g, "pauser", "Pauser", pk250_1[2:])
	assert.NoError(t, err)
	assert.Equal(t, hasKey, false)
}

func TestMultiSig_PauserCanAddKey(t *testing.T) {
	g := gwtf.NewGoWithTheFlow(util.FlowJSON, os.Getenv("NETWORK"), false, 1)

	pk250_1 := g.Account(util.Acct250_1).Key().ToConfig().PrivateKey.PublicKey().String()
	k := util.Arg{V: pk250_1[2:], T: "String"}
	w := util.Arg{V: "250.00000000", T: "UFix64"}
	sa := util.Arg{V: uint8(1), T: "UInt8"}

	hasKey, err := util.ContainsKey(g, "pauser", "Pauser", pk250_1[2:])
	assert.NoError(t, err)
	assert.Equal(t, hasKey, false)

	txIndex, err := util.GetTxIndex(g, "pauser", "Pauser")
	newTxIndex := txIndex + 1
	assert.NoError(t, err)

	_, err = util.MultiSig_SignAndSubmit(g, true, newTxIndex, util.Acct1000, "pauser", "Pauser", "configureKey", k, w, sa)
	assert.NoError(t, err)

	_, err = util.MultiSig_ExecuteTx(g, newTxIndex, "owner", "pauser", "Pauser")
	assert.NoError(t, err)

	hasKey, err = util.ContainsKey(g, "pauser", "Pauser", pk250_1[2:])
	assert.NoError(t, err)
	assert.Equal(t, hasKey, true)

	weight, err := util.GetKeyWeight(g, util.Acct250_1, "pauser", "Pauser")
	assert.NoError(t, err)
	assert.Equal(t, w.V, weight.String())
}
