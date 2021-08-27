package vault

import (
	"strconv"
	"testing"

	"github.com/bjartek/go-with-the-flow/v2/gwtf"
	util "github.com/flow-usdc/flow-usdc"
	"github.com/stretchr/testify/assert"
)

func TestAddVaultToAccount(t *testing.T) {
	g := gwtf.NewGoWithTheFlow("../../../flow.json")

	events, err := AddVaultToAccount(g, "vaulted-account")
	assert.NoError(t, err)

	_, err = util.GetBalance(g, "vaulted-account")
	assert.NoError(t, err)

	// Test event
	if len(events) != 0 {
		util.NewExpectedEvent("FiatToken", "NewVault").AssertHasKey(t, events[0], "resourceId")
	}
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

	// Transfer the 100 token back from account A to FT vaulted-account
	_, err = TransferTokens(g, "100.00000000", "vaulted-account", "owner")
	assert.NoError(t, err)

	finalBalance, err := util.GetBalance(g, "owner")
	assert.NoError(t, err)
	assert.Equal(t, finalBalance, initialBalance)
}

func TestTransferToNonVaulted(t *testing.T) {
	g := gwtf.NewGoWithTheFlow("../../../flow.json")
	// Transfer 1 token from FT vaulted-account to Account B, which has no vault
	rawEvents, err := TransferTokens(g, "1000.00000000", "owner", "non-vaulted-account")
	assert.Error(t, err)
	assert.Empty(t, rawEvents)
}

func TestMultiSig_Transfer(t *testing.T) {
	g := gwtf.NewGoWithTheFlow("../../../flow.json")

	// make sure `vaulted-account` has Fiat Token
	transferAmount := "100.00000000"
	_, err := TransferTokens(g, transferAmount, "owner", "vaulted-account")
	assert.NoError(t, err)

	initBalance, err := util.GetBalance(g, "vaulted-account")
	assert.NoError(t, err)

	recvInitBalance, err := util.GetBalance(g, "owner")
	assert.NoError(t, err)

	// Add new payload to transfer to owner
	amount := util.Arg{V: transferAmount, T: "UFix64"}
	to := util.Arg{V: "owner", T: "Address"}

	txIndex, err := util.GetTxIndex(g, "vaulted-account", "Vault")
	assert.NoError(t, err)
	expectedNewIndex := txIndex + 1

	events, err := util.MultiSig_SignAndSubmit(g, true, txIndex+1, util.Acct500_1, "vaulted-account", "Vault", "transfer", amount, to)
	assert.NoError(t, err)

	newTxIndex, err := util.GetTxIndex(g, "vaulted-account", "Vault")
	assert.NoError(t, err)
	assert.Equal(t, expectedNewIndex, newTxIndex)

	vault, err := util.GetUUID(g, "vaulted-account", "Vault")
	assert.NoError(t, err)

	util.NewExpectedEvent("OnChainMultiSig", "NewPayloadAdded").
		AddField("resourceId", strconv.Itoa(int(vault))).
		AddField("txIndex", strconv.Itoa(int(newTxIndex))).
		AssertEqual(t, events[0])

	// Try to Execute without enough weight. This should error as there is not enough signer yet
	_, err = util.MultiSig_ExecuteTx(g, newTxIndex, "owner", "vaulted-account", "Vault")
	assert.Error(t, err)

	// Add Another Payload Signature
	// `false` for new signature for existing paylaod
	events, err = util.MultiSig_SignAndSubmit(g, false, newTxIndex, util.Acct500_2, "vaulted-account", "Vault", "transfer", amount, to)
	assert.NoError(t, err)

	util.NewExpectedEvent("OnChainMultiSig", "NewPayloadSigAdded").
		AddField("resourceId", strconv.Itoa(int(vault))).
		AddField("txIndex", strconv.Itoa(int(newTxIndex))).
		AssertEqual(t, events[0])

	// Try to Execute Tx after second signature
	events, err = util.MultiSig_ExecuteTx(g, newTxIndex, "owner", "vaulted-account", "Vault")
	assert.NoError(t, err)
	util.NewExpectedEvent("FiatToken", "FiatTokenWithdrawn").
		AddField("amount", transferAmount).
		AddField("from", strconv.Itoa(int(vault))).
		AssertEqual(t, events[0])

	fromAddr := util.GetAccountAddr(g, "vaulted-account")
	util.NewExpectedEvent("FiatToken", "TokensWithdrawn").
		AddField("amount", transferAmount).
		AddField("from", fromAddr).
		AssertEqual(t, events[1])

	owner_vault, err := util.GetUUID(g, "owner", "Vault")
	assert.NoError(t, err)
	util.NewExpectedEvent("FiatToken", "FiatTokenDeposited").
		AddField("amount", transferAmount).
		AddField("to", strconv.Itoa(int(owner_vault))).
		AssertEqual(t, events[2])

	toAddr := util.GetAccountAddr(g, "owner")
	util.NewExpectedEvent("FiatToken", "TokensDeposited").
		AddField("amount", transferAmount).
		AddField("to", toAddr).
		AssertEqual(t, events[3])

	postBalance, err := util.GetBalance(g, "vaulted-account")
	assert.NoError(t, err)
	recvPostBalance, err := util.GetBalance(g, "owner")
	assert.NoError(t, err)
	assert.Equal(t, transferAmount, (initBalance - postBalance).String())
	assert.Equal(t, transferAmount, (recvPostBalance - recvInitBalance).String())
}

func TestMultiSig_VaultUnknowMethodFails(t *testing.T) {
	g := gwtf.NewGoWithTheFlow("../../../flow.json")
	mc := util.Arg{V: uint64(222), T: "UInt64"}
	m := util.Arg{V: uint64(111), T: "UInt64"}

	txIndex, err := util.GetTxIndex(g, "vaulted-account", "Vault")
	assert.NoError(t, err)

	_, err = util.MultiSig_SignAndSubmit(g, true, txIndex+1, util.Acct1000, "vaulted-account", "Vault", "UnknownMethod", m, mc)
	assert.NoError(t, err)

	newTxIndex, err := util.GetTxIndex(g, "vaulted-account", "Vault")
	assert.NoError(t, err)

	_, err = util.MultiSig_ExecuteTx(g, newTxIndex, "owner", "vaulted-account", "Vault")
	assert.Error(t, err)
}

func TestMultiSig_VaultCanRemoveKey(t *testing.T) {
	g := gwtf.NewGoWithTheFlow("../../../flow.json")
	pk250_1 := g.Accounts[util.Acct250_1].PrivateKey.PublicKey().String()
	k := util.Arg{V: pk250_1[2:], T: "String"}

	hasKey, err := util.ContainsKey(g, "vaulted-account", "Vault", pk250_1[2:])
	assert.NoError(t, err)
	assert.Equal(t, hasKey, true)

	txIndex, err := util.GetTxIndex(g, "vaulted-account", "Vault")
	newTxIndex := txIndex + 1
	assert.NoError(t, err)

	_, err = util.MultiSig_SignAndSubmit(g, true, newTxIndex, util.Acct1000, "vaulted-account", "Vault", "removeKey", k)
	assert.NoError(t, err)

	_, err = util.MultiSig_ExecuteTx(g, newTxIndex, "owner", "vaulted-account", "Vault")
	assert.NoError(t, err)

	hasKey, err = util.ContainsKey(g, "vaulted-account", "Vault", pk250_1[2:])
	assert.NoError(t, err)
	assert.Equal(t, hasKey, false)
}

func TestMultiSig_VaultCanAddKey(t *testing.T) {
	g := gwtf.NewGoWithTheFlow("../../../flow.json")
	pk250_1 := g.Accounts[util.Acct250_1].PrivateKey.PublicKey().String()
	k := util.Arg{V: pk250_1[2:], T: "String"}
	w := util.Arg{V: "250.00000000", T: "UFix64"}

	hasKey, err := util.ContainsKey(g, "vaulted-account", "Vault", pk250_1[2:])
	assert.NoError(t, err)
	assert.Equal(t, hasKey, false)

	txIndex, err := util.GetTxIndex(g, "vaulted-account", "Vault")
	newTxIndex := txIndex + 1
	assert.NoError(t, err)

	_, err = util.MultiSig_SignAndSubmit(g, true, newTxIndex, util.Acct1000, "vaulted-account", "Vault", "configureKey", k, w)
	assert.NoError(t, err)

	_, err = util.MultiSig_ExecuteTx(g, newTxIndex, "owner", "vaulted-account", "Vault")
	assert.NoError(t, err)

	hasKey, err = util.ContainsKey(g, "vaulted-account", "Vault", pk250_1[2:])
	assert.NoError(t, err)
	assert.Equal(t, hasKey, true)

	weight, err := util.GetKeyWeight(g, util.Acct250_1, "vaulted-account", "Vault")
	assert.NoError(t, err)
	assert.Equal(t, w.V, weight.String())
}
