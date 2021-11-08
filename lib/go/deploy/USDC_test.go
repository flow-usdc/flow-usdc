package deploy

import (
	"encoding/hex"
	"os"
	"strconv"
	"testing"

	"github.com/bjartek/go-with-the-flow/v2/gwtf"
	util "github.com/flow-usdc/flow-usdc"
	"github.com/flow-usdc/flow-usdc/vault"
	"github.com/stretchr/testify/assert"
)

func TestFiatTokenTotalSupplyInContractOwnerVault(t *testing.T) {
	g := gwtf.NewGoWithTheFlow(util.FlowJSON, os.Getenv("NETWORK"), false, 1)
	supply, err := util.GetTotalSupply(g)
	assert.NoError(t, err)

	balance, err := util.GetBalance(g, "owner")
	assert.NoError(t, err)

	// This assertion can only  happen on the first deploy on testnet as upgrades will not
	// reset values
	if g.Network == "emulator" {
		assert.Equal(t, "1000000000.00000000", supply.String())
		assert.Equal(t, "1000000000.00000000", balance.String())
	}
}

func TestFiatTokenName(t *testing.T) {
	g := gwtf.NewGoWithTheFlow(util.FlowJSON, os.Getenv("NETWORK"), false, 1)
	name, err := util.GetName(g)
	assert.NoError(t, err)
	assert.Equal(t, "USDC", name)
}

func TestFiatTokenVersion(t *testing.T) {
	g := gwtf.NewGoWithTheFlow(util.FlowJSON, os.Getenv("NETWORK"), false, 1)
	version, err := util.GetVersion(g)
	assert.NoError(t, err)
	assert.Equal(t, "0.1.0", version)
}

func TestUpgradeContract(t *testing.T) {

	g := gwtf.NewGoWithTheFlow(util.FlowJSON, os.Getenv("NETWORK"), false, 3)

	currentVersion, err := util.GetVersion(g)
	assert.NoError(t, err)

	newVersion := "0.3.0"
	assert.NotEqual(t, currentVersion, newVersion)

	_, err = UpgradeFiatTokenContract(g, "owner", newVersion)
	assert.NoError(t, err)

	version, err := util.GetVersion(g)
	assert.NoError(t, err)
	assert.Equal(t, newVersion, version)
}

func TestMultiSig_UpgradeContract(t *testing.T) {
	g := gwtf.NewGoWithTheFlow(util.FlowJSON, os.Getenv("NETWORK"), false, 1)

	// Add New Payload
	currentIndex, err := util.GetTxIndex(g, "owner", "Admin")
	assert.NoError(t, err)
	expectedNewIndex := currentIndex + 1

	currentVersion, err := util.GetVersion(g)
	assert.NoError(t, err)
	newV := "0.5.0"
	assert.NotEqual(t, currentVersion, newV)

	contractCode := util.ParseCadenceTemplate("../../../contracts/FiatToken.cdc")
	encodedStr := util.Arg{V: hex.EncodeToString(contractCode), T: "String"}
	newVersion := util.Arg{V: newV, T: "String"}
	name := util.Arg{V: "FiatToken", T: "String"}
	admin, err := util.GetUUID(g, "owner", "Admin")
	assert.NoError(t, err)

	events, err := util.MultiSig_SignAndSubmit(g, true, expectedNewIndex, util.Acct500_1, "owner", "Admin", "upgradeContract", name, encodedStr, newVersion)
	assert.NoError(t, err)

	newTxIndex, err := util.GetTxIndex(g, "owner", "Admin")
	assert.NoError(t, err)
	assert.Equal(t, expectedNewIndex, newTxIndex)

	util.NewExpectedEvent("OnChainMultiSig", "NewPayloadAdded").
		AddField("resourceId", strconv.Itoa(int(admin))).
		AddField("txIndex", strconv.Itoa(int(newTxIndex))).
		AssertEqual(t, events[0])

	_, err = vault.AddVaultToAccount(g, "vaulted-account")
	assert.NoError(t, err)

	// Try to Execute without enough weight. This should error as there is not enough signer yet
	_, err = util.MultiSig_ExecuteTx(g, newTxIndex, "vaulted-account", "owner", "Admin")
	assert.Error(t, err)

	// Add Another Payload Signature
	// `false` for new signature for existing paylaod
	events, err = util.MultiSig_SignAndSubmit(g, false, expectedNewIndex, util.Acct500_2, "owner", "Admin", "upgradeContract", name, encodedStr, newVersion)
	assert.NoError(t, err)

	util.NewExpectedEvent("OnChainMultiSig", "NewPayloadSigAdded").
		AddField("resourceId", strconv.Itoa(int(admin))).
		AddField("txIndex", strconv.Itoa(int(newTxIndex))).
		AssertEqual(t, events[0])

	events, err = util.MultiSig_ExecuteTx(g, newTxIndex, "vaulted-account", "owner", "Admin")
	assert.NoError(t, err)

	// Test event
	assert.Equal(t, events[0].Name, "flow.AccountContractUpdated")

	version, err := util.GetVersion(g)
	assert.NoError(t, err)
	assert.Equal(t, newV, version)
}

func TestMultiSig_UpgradeContractRemovePayload(t *testing.T) {
	g := gwtf.NewGoWithTheFlow(util.FlowJSON, os.Getenv("NETWORK"), false, 1)

	currentIndex, err := util.GetTxIndex(g, "owner", "Admin")
	assert.NoError(t, err)
	expectedNewIndex := currentIndex + 1

	currentVersion, err := util.GetVersion(g)
	assert.NoError(t, err)

	contractCode := util.ParseCadenceTemplate("../../../contracts/FiatToken.cdc")
	encodedStr := util.Arg{V: hex.EncodeToString(contractCode), T: "String"}
	newVersion := util.Arg{V: "0.7.9", T: "String"}
	name := util.Arg{V: "FiatToken", T: "String"}

	_, err = util.MultiSig_SignAndSubmit(g, true, expectedNewIndex, util.Acct500_1, "owner", "Admin", "upgradeContract", name, encodedStr, newVersion)
	assert.NoError(t, err)

	payloadToRemove, err := util.GetTxIndex(g, "owner", "Admin")
	assert.NoError(t, err)
	r := util.Arg{V: payloadToRemove, T: "UInt64"}

	// We submit another payload requesting to remove the previous one
	// `true` for new payload signed by account with full weight
	_, err = util.MultiSig_SignAndSubmit(g, true, expectedNewIndex+1, util.Acct1000, "owner", "Admin", "removePayload", r)
	assert.NoError(t, err)

	_, err = util.MultiSig_ExecuteTx(g, expectedNewIndex+1, "vaulted-account", "owner", "Admin")
	assert.NoError(t, err)

	postVersion, err := util.GetVersion(g)
	assert.NoError(t, err)
	assert.Equal(t, currentVersion, postVersion)
}

func TestMultiSig_UpgradeContractUnknownMethodFails(t *testing.T) {
	g := gwtf.NewGoWithTheFlow(util.FlowJSON, os.Getenv("NETWORK"), false, 1)
	mc := util.Arg{V: uint64(222), T: "UInt64"}

	txIndex, err := util.GetTxIndex(g, "owner", "Admin")
	assert.NoError(t, err)

	_, err = util.MultiSig_SignAndSubmit(g, true, txIndex+1, util.Acct1000, "owner", "Admin", "UKNOWMETHOD", mc)
	assert.NoError(t, err)

	newTxIndex, err := util.GetTxIndex(g, "owner", "Admin")
	assert.NoError(t, err)

	_, err = util.MultiSig_ExecuteTx(g, newTxIndex, "vaulted-account", "owner", "Admin")
	assert.Error(t, err)
}

func TestMultiSig_UpgradeContractCanRemoveKey(t *testing.T) {
	g := gwtf.NewGoWithTheFlow(util.FlowJSON, os.Getenv("NETWORK"), false, 1)
	pk250_1 := g.Account(util.Acct250_1).Key().ToConfig().PrivateKey.PublicKey().String()
	k := util.Arg{V: pk250_1[2:], T: "String"}

	hasKey, err := util.ContainsKey(g, "owner", "Admin", pk250_1[2:])
	assert.NoError(t, err)
	assert.Equal(t, hasKey, true)

	txIndex, err := util.GetTxIndex(g, "owner", "Admin")
	newTxIndex := txIndex + 1
	assert.NoError(t, err)

	_, err = util.MultiSig_SignAndSubmit(g, true, newTxIndex, util.Acct1000, "owner", "Admin", "removeKey", k)
	assert.NoError(t, err)

	_, err = util.MultiSig_ExecuteTx(g, newTxIndex, "vaulted-account", "owner", "Admin")
	assert.NoError(t, err)

	hasKey, err = util.ContainsKey(g, "owner", "Admin", pk250_1[2:])
	assert.NoError(t, err)
	assert.Equal(t, hasKey, false)
}

func TestMultiSig_UpgradeContractCanAddKey(t *testing.T) {
	g := gwtf.NewGoWithTheFlow(util.FlowJSON, os.Getenv("NETWORK"), false, 1)
	pk250_1 := g.Account(util.Acct250_1).Key().ToConfig().PrivateKey.PublicKey().String()

	k := util.Arg{V: pk250_1[2:], T: "String"}
	w := util.Arg{V: "250.00000000", T: "UFix64"}
	sa := util.Arg{V: uint8(1), T: "UInt8"}

	hasKey, err := util.ContainsKey(g, "owner", "Admin", pk250_1[2:])
	assert.NoError(t, err)
	assert.Equal(t, hasKey, false)

	txIndex, err := util.GetTxIndex(g, "owner", "Admin")
	newTxIndex := txIndex + 1
	assert.NoError(t, err)

	_, err = util.MultiSig_SignAndSubmit(g, true, newTxIndex, util.Acct1000, "owner", "Admin", "configureKey", k, w, sa)
	assert.NoError(t, err)

	_, err = util.MultiSig_ExecuteTx(g, newTxIndex, "vaulted-account", "owner", "Admin")
	assert.NoError(t, err)

	hasKey, err = util.ContainsKey(g, "owner", "Admin", pk250_1[2:])
	assert.NoError(t, err)
	assert.Equal(t, hasKey, true)

	weight, err := util.GetKeyWeight(g, util.Acct250_1, "owner", "Admin")
	assert.NoError(t, err)
	assert.Equal(t, w.V, weight.String())
}
