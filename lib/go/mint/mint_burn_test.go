package mint

import (
	"strconv"
	"testing"

	"github.com/bjartek/go-with-the-flow/gwtf"
	util "github.com/flow-usdc/flow-usdc"
	"github.com/flow-usdc/flow-usdc/blocklist"
	"github.com/flow-usdc/flow-usdc/pause"
	"github.com/flow-usdc/flow-usdc/vault"
	"github.com/stretchr/testify/assert"
)

func TestMintBurn_MintWithoutConfig(t *testing.T) {
	g := gwtf.NewGoWithTheFlow("../../../flow.json")

	createEvents, err := CreateMinter(g, "non-minter")
	assert.NoError(t, err)

	// Execute mint without minterController config
	mintRawEvents, err := Mint(g, "non-minter", "10.00000000", "non-minter")
	assert.Error(t, err)
	assert.Empty(t, mintRawEvents)

	// Test event
	util.NewExpectedEvent("FiatToken", "MinterCreated").AssertHasKey(t, createEvents[0], "resourceId")
}

func TestMintBurn_MintBelowAllowace(t *testing.T) {
	g := gwtf.NewGoWithTheFlow("../../../flow.json")

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
	g := gwtf.NewGoWithTheFlow("../../../flow.json")

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

func TestMintBurn_FailToMintAboveAllowace(t *testing.T) {
	g := gwtf.NewGoWithTheFlow("../../../flow.json")

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
	g := gwtf.NewGoWithTheFlow("../../../flow.json")

	// Pause contract
	_, err := pause.PauseOrUnpauseContract(g, "pauser", 1)
	assert.NoError(t, err)
	paused, err := pause.GetPaused(g)
	assert.NoError(t, err)
	assert.Equal(t, paused.String(), "true")

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
	g := gwtf.NewGoWithTheFlow("../../../flow.json")

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

func TestMintBurn_FailedToMintOrBurnAfterRemoved(t *testing.T) {
	g := gwtf.NewGoWithTheFlow("../../../flow.json")

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
