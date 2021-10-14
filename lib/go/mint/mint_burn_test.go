package mint

import (
	"os"
	"strconv"
	"testing"

	"github.com/bjartek/go-with-the-flow/v2/gwtf"
	util "github.com/flow-usdc/flow-usdc"
	"github.com/flow-usdc/flow-usdc/blocklist"
	"github.com/flow-usdc/flow-usdc/pause"
	"github.com/flow-usdc/flow-usdc/vault"
	"github.com/stretchr/testify/assert"
)

func TestMintBurn_MintWithoutConfig(t *testing.T) {
	g := gwtf.NewGoWithTheFlow(util.FlowJSON, os.Getenv("NETWORK"), false, 1)

	createEvents, err := CreateMinter(g, "non-minter")
	assert.NoError(t, err)

	// Execute mint without minterController config
	mintRawEvents, err := Mint(g, "non-minter", "10.00000000", "non-minter")
	assert.Error(t, err)
	assert.Empty(t, mintRawEvents)

	// Test event
	util.NewExpectedEvent("FiatToken", "MinterCreated").AssertHasKey(t, createEvents[0], "resourceId")
}

func TestMintBurn_MintBelowAllowance(t *testing.T) {
	g := gwtf.NewGoWithTheFlow(util.FlowJSON, os.Getenv("NETWORK"), false, 1)

	// Params
	_, err := vault.AddVaultToAccount(g, "minter")
	assert.NoError(t, err)
	minter, err := util.GetUUID(g, "minter", "Minter")
	assert.NoError(t, err)

	// Initial values
	initTotalSupply, err := util.GetTotalSupply(g)
	assert.NoError(t, err)
	initBalance, err := util.GetBalance(g, "minter")
	assert.NoError(t, err)
	initMintAllowance, err := GetMinterAllowance(g, minter)
	assert.NoError(t, err)
	mintAmount := initMintAllowance / 2.0

	// Execute mint
	events, err := Mint(g, "minter", mintAmount.String(), "minter")
	assert.NoError(t, err)

	// Post mint values
	postTotalSupply, err := util.GetTotalSupply(g)
	assert.NoError(t, err)
	postBalance, err := util.GetBalance(g, "minter")
	assert.NoError(t, err)
	postMintAllowance, err := GetMinterAllowance(g, minter)
	assert.NoError(t, err)

	// Assertions
	assert.Equal(t, mintAmount, postTotalSupply-initTotalSupply)
	assert.Equal(t, mintAmount, postBalance-initBalance)
	assert.Equal(t, mintAmount, initMintAllowance-postMintAllowance)

	util.NewExpectedEvent("FiatToken", "Mint").
		AddField("minter", strconv.Itoa(int(minter))).
		AddField("amount", mintAmount.String()).
		AssertEqual(t, events[0])

	uuid, err := util.GetUUID(g, "minter", "Vault")
	assert.NoError(t, err)
	util.NewExpectedEvent("FiatToken", "FiatTokenDeposited").
		AddField("amount", mintAmount.String()).
		AddField("to", strconv.Itoa(int(uuid))).
		AssertEqual(t, events[1])

	toAddr := util.GetAccountAddr(g, "minter")
	util.NewExpectedEvent("FiatToken", "TokensDeposited").
		AddField("amount", mintAmount.String()).
		AddField("to", toAddr).
		AssertEqual(t, events[2])

	util.NewExpectedEvent("FiatToken", "DestroyVault").
		AssertHasKey(t, events[3], "resourceId")
}

func TestMintBurn_Burn(t *testing.T) {
	g := gwtf.NewGoWithTheFlow(util.FlowJSON, os.Getenv("NETWORK"), false, 1)

	minter, err := util.GetUUID(g, "minter", "Minter")
	assert.NoError(t, err)

	// Initial values
	initTotalSupply, err := util.GetTotalSupply(g)
	assert.NoError(t, err)
	initBalance, err := util.GetBalance(g, "minter")
	assert.NoError(t, err)
	initMintAllowance, err := GetMinterAllowance(g, minter)
	assert.NoError(t, err)
	burnAmount := initBalance / 2.0

	// Execute mint
	events, err := Burn(g, "minter", burnAmount.String())
	assert.NoError(t, err)

	// Post mint values
	postTotalSupply, err := util.GetTotalSupply(g)
	assert.NoError(t, err)
	postBalance, err := util.GetBalance(g, "minter")
	assert.NoError(t, err)
	postMintAllowance, err := GetMinterAllowance(g, minter)
	assert.NoError(t, err)

	// Assertions
	assert.Equal(t, burnAmount, initTotalSupply-postTotalSupply)
	assert.Equal(t, burnAmount, initBalance-postBalance)
	assert.Equal(t, postMintAllowance, initMintAllowance)

	uuid, err := util.GetUUID(g, "minter", "Vault")
	assert.NoError(t, err)
	util.NewExpectedEvent("FiatToken", "FiatTokenWithdrawn").
		AddField("amount", burnAmount.String()).
		AddField("from", strconv.Itoa(int(uuid))).
		AssertEqual(t, events[0])

	toAddr := util.GetAccountAddr(g, "minter")

	// Check the events in order: [withdraw (Fiat)], withdraw (FT), vault destroyed, burn
	util.NewExpectedEvent("FiatToken", "TokensWithdrawn").
		AddField("amount", burnAmount.String()).
		AddField("from", toAddr).
		AssertEqual(t, events[1])

	util.NewExpectedEvent("FiatToken", "DestroyVault").
		AssertHasKey(t, events[2], "resourceId")

	util.NewExpectedEvent("FiatToken", "Burn").
		AddField("minter", strconv.Itoa(int(minter))).
		AddField("amount", burnAmount.String()).
		AssertEqual(t, events[3])
}

func TestMintBurn_FailToMintAboveAllowance(t *testing.T) {
	g := gwtf.NewGoWithTheFlow(util.FlowJSON, os.Getenv("NETWORK"), false, 1)

	// Params
	minter, err := util.GetUUID(g, "minter", "Minter")
	assert.NoError(t, err)

	// Initial values
	initTotalSupply, err := util.GetTotalSupply(g)
	assert.NoError(t, err)
	initBalance, err := util.GetBalance(g, "minter")
	assert.NoError(t, err)
	initMintAllowance, err := GetMinterAllowance(g, minter)
	assert.NoError(t, err)
	mintAmount := initMintAllowance + 2.0

	// Execute mint
	rawEvents, err := Mint(g, "minter", mintAmount.String(), "minter")
	assert.Error(t, err)
	assert.Empty(t, rawEvents)

	// Post mint values
	postTotalSupply, err := util.GetTotalSupply(g)
	assert.NoError(t, err)
	postBalance, err := util.GetBalance(g, "minter")
	assert.NoError(t, err)
	postMintAllowance, err := GetMinterAllowance(g, minter)
	assert.NoError(t, err)

	// Assertions values should not change
	assert.Equal(t, postTotalSupply, initTotalSupply)
	assert.Equal(t, postBalance, initBalance)
	assert.Equal(t, initMintAllowance, postMintAllowance)
}

func TestMintBurn_FailToMintOrBurnWhenPause(t *testing.T) {
	g := gwtf.NewGoWithTheFlow(util.FlowJSON, os.Getenv("NETWORK"), false, 1)

	// Pause contract
	_, err := pause.PauseOrUnpauseContract(g, "pauser", 1)
	assert.NoError(t, err)
	paused, err := pause.GetPaused(g)
	assert.NoError(t, err)
	assert.Equal(t, true, paused)

	// Ensure all amounts would be valid in unpaused case
	minter, err := util.GetUUID(g, "minter", "Minter")
	assert.NoError(t, err)
	initBalance, err := util.GetBalance(g, "minter")
	assert.NoError(t, err)
	initMintAllowance, err := GetMinterAllowance(g, minter)
	assert.NoError(t, err)
	burnAmount := initBalance / 2.0
	mintAmount := initMintAllowance / 2.0

	// Execute mint/burn should error as contract is paused
	mEvents, err := Mint(g, "minter", mintAmount.String(), "minter")
	assert.Error(t, err)
	assert.Empty(t, mEvents)

	bEvents, err := Burn(g, "minter", burnAmount.String())
	assert.Error(t, err)
	assert.Empty(t, bEvents)

	_, err = pause.PauseOrUnpauseContract(g, "pauser", 0)
	assert.NoError(t, err)
}

func TestMintBurn_FailToMintOrBurnWhenBlocklisted(t *testing.T) {
	g := gwtf.NewGoWithTheFlow(util.FlowJSON, os.Getenv("NETWORK"), false, 1)

	minter, err := util.GetUUID(g, "minter", "Minter")
	assert.NoError(t, err)

	// blocklist minter
	_, err = blocklist.BlocklistOrUnblocklistRsc(g, "blocklister", minter, 1)
	assert.NoError(t, err)
	blockheight, err := blocklist.GetBlocklistStatus(g, minter)
	assert.NoError(t, err)
	assert.Equal(t, true, blockheight > 0)

	// Ensure all amounts would be valid in unblocklisted case
	initBalance, err := util.GetBalance(g, "minter")
	assert.NoError(t, err)
	initMintAllowance, err := GetMinterAllowance(g, minter)
	assert.NoError(t, err)
	burnAmount := initBalance / 2.0
	mintAmount := initMintAllowance / 2.0

	// Execute mint/burn should error as minter is blocklisted
	mEvents, err := Mint(g, "minter", mintAmount.String(), "minter")
	assert.Error(t, err)
	assert.Empty(t, mEvents)

	bEvents, err := Burn(g, "minter", burnAmount.String())
	assert.Error(t, err)
	assert.Empty(t, bEvents)

	_, err = blocklist.BlocklistOrUnblocklistRsc(g, "blocklister", minter, 0)
	assert.NoError(t, err)
}

func TestMintBurnMultiSig_MintTo(t *testing.T) {
	g := gwtf.NewGoWithTheFlow(util.FlowJSON, os.Getenv("NETWORK"), false, 1)
	_, err := vault.AddVaultToAccount(g, util.Acct1000)
	assert.NoError(t, err)
	_, err = vault.AddVaultToAccount(g, util.Acct500_1)
	assert.NoError(t, err)
	// Add New Payload
	currentIndex, err := util.GetTxIndex(g, "minter", "Minter")
	assert.NoError(t, err)
	expectedNewIndex := currentIndex + 1

	// Params
	minter, err := util.GetUUID(g, "minter", "Minter")
	assert.NoError(t, err)
	initMintAllowance, err := GetMinterAllowance(g, minter)
	assert.NoError(t, err)
	initBalance, err := util.GetBalance(g, util.Acct1000)
	assert.NoError(t, err)

	mintAmount := initMintAllowance / 2.0
	m := util.Arg{V: mintAmount.String(), T: "UFix64"}
	to := util.Arg{V: util.Acct1000, T: "Address"}
	// `true` for new payload
	// signed by account with full weight
	events, err := util.MultiSig_SignAndSubmit(g, true, expectedNewIndex, util.Acct500_1, "minter", "Minter", "mintTo", m, to)
	assert.NoError(t, err)

	newTxIndex, err := util.GetTxIndex(g, "minter", "Minter")
	assert.NoError(t, err)
	assert.Equal(t, expectedNewIndex, newTxIndex)

	util.NewExpectedEvent("OnChainMultiSig", "NewPayloadAdded").
		AddField("resourceId", strconv.Itoa(int(minter))).
		AddField("txIndex", strconv.Itoa(int(newTxIndex))).
		AssertEqual(t, events[0])

	// Try to Execute without enough weight. This should error as there is not enough signer yet
	_, err = util.MultiSig_ExecuteTx(g, newTxIndex, "owner", "minter", "Minter")
	assert.Error(t, err)

	// Add Another Payload Signature
	// `false` for new signature for existing paylaod
	events, err = util.MultiSig_SignAndSubmit(g, false, newTxIndex, util.Acct500_2, "minter", "Minter", "mintTo", m, to)
	assert.NoError(t, err)

	util.NewExpectedEvent("OnChainMultiSig", "NewPayloadSigAdded").
		AddField("resourceId", strconv.Itoa(int(minter))).
		AddField("txIndex", strconv.Itoa(int(newTxIndex))).
		AssertEqual(t, events[0])

	// Try to Execute Tx after second signature
	events, err = util.MultiSig_ExecuteTx(g, newTxIndex, util.Acct500_1, "minter", "Minter")
	assert.NoError(t, err)

	util.NewExpectedEvent("FiatToken", "Mint").
		AddField("minter", strconv.Itoa(int(minter))).
		AddField("amount", mintAmount.String()).
		AssertEqual(t, events[0])

	postBalance, err := util.GetBalance(g, util.Acct1000)
	assert.NoError(t, err)
	assert.Equal(t, mintAmount.String(), (postBalance - initBalance).String())
}

func TestMintBurnMultiSig_Burn(t *testing.T) {
	g := gwtf.NewGoWithTheFlow(util.FlowJSON, os.Getenv("NETWORK"), false, 1)

	// Transfer FiatTokens into the minter account to burn
	burnAmount := "100.00000000"
	_, err := vault.TransferTokens(g, burnAmount, "owner", "minter")
	assert.NoError(t, err)

	// Add New Payload
	currentIndex, err := util.GetTxIndex(g, "minter", "Minter")
	assert.NoError(t, err)
	expectedNewIndex := currentIndex + 1

	// Params
	minter, err := util.GetUUID(g, "minter", "Minter")
	assert.NoError(t, err)
	toAddr := util.GetAccountAddr(g, "minter")
	initBalance, err := util.GetBalance(g, "minter")
	assert.NoError(t, err)
	m := util.Arg{V: burnAmount, T: "UFix64"}
	// `true` for new payload
	// signed by account with full weight
	events, err := util.MultiSig_SignAndSubmitNewPayload(g, expectedNewIndex, util.Acct1000, "minter", "Minter", "burn", m)
	assert.NoError(t, err)

	newTxIndex, err := util.GetTxIndex(g, "minter", "Minter")
	assert.NoError(t, err)
	assert.Equal(t, expectedNewIndex, newTxIndex)

	util.NewExpectedEvent("OnChainMultiSig", "NewPayloadAdded").
		AddField("resourceId", strconv.Itoa(int(minter))).
		AddField("txIndex", strconv.Itoa(int(newTxIndex))).
		AssertEqual(t, events[0])

	// Try to Execute Tx after second signature
	events, err = util.MultiSig_ExecuteTx(g, newTxIndex, "owner", "minter", "Minter")
	assert.NoError(t, err)

	// Check the events in order: [withdraw (Fiat)], withdraw (FT), vault destroyed, burn
	util.NewExpectedEvent("FiatToken", "TokensWithdrawn").
		AddField("amount", burnAmount).
		AddField("from", toAddr).
		AssertEqual(t, events[1])

	util.NewExpectedEvent("FiatToken", "DestroyVault").
		AssertHasKey(t, events[2], "resourceId")

	util.NewExpectedEvent("FiatToken", "Burn").
		AddField("minter", strconv.Itoa(int(minter))).
		AddField("amount", burnAmount).
		AssertEqual(t, events[3])

	postBalance, err := util.GetBalance(g, "minter")
	assert.NoError(t, err)
	assert.Equal(t, burnAmount, (initBalance - postBalance).String())
}

func TestMintBurnMultiSig_RemovePayload(t *testing.T) {
	g := gwtf.NewGoWithTheFlow(util.FlowJSON, os.Getenv("NETWORK"), false, 1)

	// Add New Payload that burns some token
	// This will be removed in the second step
	currentIndex, err := util.GetTxIndex(g, "minter", "Minter")
	assert.NoError(t, err)
	expectedNewIndex := currentIndex + 1

	burnAmount, err := util.GetBalance(g, util.Acct500_1)
	assert.NoError(t, err)
	m := util.Arg{V: burnAmount.String(), T: "UFix64"}
	// `true` for new payload
	_, err = util.MultiSig_SignAndSubmitNewPayload(g, expectedNewIndex, util.Acct500_1, "minter", "Minter", "burn", m)
	assert.NoError(t, err)
	postBalance, err := util.GetBalance(g, util.Acct500_1)
	assert.NoError(t, err)
	assert.Equal(t, "0.00000000", postBalance.String())

	payloadToRemove, err := util.GetTxIndex(g, "minter", "Minter")
	assert.NoError(t, err)
	r := util.Arg{V: payloadToRemove, T: "UInt64"}

	// We submit another payload requesting to remove the previous one
	// `true` for new payload
	// signed by account with full weight
	_, err = util.MultiSig_SignAndSubmit(g, true, expectedNewIndex+1, util.Acct1000, "minter", "Minter", "removePayload", r)
	assert.NoError(t, err)

	_, err = util.MultiSig_ExecuteTx(g, expectedNewIndex+1, util.Acct500_1, "minter", "Minter")
	assert.NoError(t, err)

	postBalance, err = util.GetBalance(g, util.Acct500_1)
	assert.NoError(t, err)
	assert.Equal(t, burnAmount.String(), postBalance.String())
}

func TestMintBurnMultiSig_MinterUnknowMethodFails(t *testing.T) {
	g := gwtf.NewGoWithTheFlow(util.FlowJSON, os.Getenv("NETWORK"), false, 1)
	mc := util.Arg{V: uint64(222), T: "UInt64"}
	m := util.Arg{V: uint64(111), T: "UInt64"}

	txIndex, err := util.GetTxIndex(g, "minter", "Minter")
	assert.NoError(t, err)

	_, err = util.MultiSig_SignAndSubmit(g, true, txIndex+1, util.Acct1000, "minter", "Minter", "configureUKNOWMETHODController", m, mc)
	assert.NoError(t, err)

	newTxIndex, err := util.GetTxIndex(g, "minter", "Minter")
	assert.NoError(t, err)

	_, err = util.MultiSig_ExecuteTx(g, newTxIndex, "owner", "minter", "Minter")
	assert.Error(t, err)
}

func TestMintBurnMultiSig_MinterCanRemoveKey(t *testing.T) {
	g := gwtf.NewGoWithTheFlow(util.FlowJSON, os.Getenv("NETWORK"), false, 1)
	pk250_1 := g.Account(util.Acct250_1).Key().ToConfig().PrivateKey.PublicKey().String()
	k := util.Arg{V: pk250_1[2:], T: "String"}

	hasKey, err := util.ContainsKey(g, "minter", "Minter", pk250_1[2:])
	assert.NoError(t, err)
	assert.Equal(t, hasKey, true)

	txIndex, err := util.GetTxIndex(g, "minter", "Minter")
	newTxIndex := txIndex + 1
	assert.NoError(t, err)

	_, err = util.MultiSig_SignAndSubmit(g, true, newTxIndex, util.Acct1000, "minter", "Minter", "removeKey", k)
	assert.NoError(t, err)

	_, err = util.MultiSig_ExecuteTx(g, newTxIndex, "owner", "minter", "Minter")
	assert.NoError(t, err)

	hasKey, err = util.ContainsKey(g, "minter", "Minter", pk250_1[2:])
	assert.NoError(t, err)
	assert.Equal(t, hasKey, false)
}

func TestMintBurnMultiSig_MinterCanAddKey(t *testing.T) {
	g := gwtf.NewGoWithTheFlow(util.FlowJSON, os.Getenv("NETWORK"), false, 1)
	pk250_1 := g.Account(util.Acct250_1).Key().ToConfig().PrivateKey.PublicKey().String()

	k := util.Arg{V: pk250_1[2:], T: "String"}
	w := util.Arg{V: "250.00000000", T: "UFix64"}
	sa := util.Arg{V: uint8(1), T: "UInt8"}

	hasKey, err := util.ContainsKey(g, "minter", "Minter", pk250_1[2:])
	assert.NoError(t, err)
	assert.Equal(t, hasKey, false)

	txIndex, err := util.GetTxIndex(g, "minter", "Minter")
	newTxIndex := txIndex + 1
	assert.NoError(t, err)

	_, err = util.MultiSig_SignAndSubmit(g, true, newTxIndex, util.Acct1000, "minter", "Minter", "configureKey", k, w, sa)
	assert.NoError(t, err)

	_, err = util.MultiSig_ExecuteTx(g, newTxIndex, "owner", "minter", "Minter")
	assert.NoError(t, err)

	hasKey, err = util.ContainsKey(g, "minter", "Minter", pk250_1[2:])
	assert.NoError(t, err)
	assert.Equal(t, hasKey, true)

	weight, err := util.GetKeyWeight(g, util.Acct250_1, "minter", "Minter")
	assert.NoError(t, err)
	assert.Equal(t, w.V, weight.String())
}

func TestMintBurn_FailedToMintOrBurnAfterRemoved(t *testing.T) {
	g := gwtf.NewGoWithTheFlow(util.FlowJSON, os.Getenv("NETWORK"), false, 1)

	// Ensure all amounts would be valid in valid case
	minter, err := util.GetUUID(g, "minter", "Minter")
	assert.NoError(t, err)
	initBalance, err := util.GetBalance(g, "minter")
	assert.NoError(t, err)
	initMintAllowance, err := GetMinterAllowance(g, minter)
	assert.NoError(t, err)
	burnAmount := initBalance / 2.0
	mintAmount := initMintAllowance / 2.0

	// "minterController1" controls "minter" and removes it
	_, err = RemoveMinter(g, "minterController1")
	assert.NoError(t, err)

	// Execute mint/burn should error
	mEvents, err := Mint(g, "minter", mintAmount.String(), "minter")
	assert.Error(t, err)
	assert.Empty(t, mEvents)

	bEvents, err := Burn(g, "minter", burnAmount.String())
	assert.Error(t, err)
	assert.Empty(t, bEvents)
}
