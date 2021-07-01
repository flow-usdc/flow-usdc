package pause

import (
	"context"

	util "github.com/flow-usdc/flow-usdc"
	"github.com/onflow/cadence"
	"github.com/onflow/flow-go-sdk"
	"github.com/onflow/flow-go-sdk/client"
	"github.com/onflow/flow-go-sdk/crypto"
)

func CreatePauser(
	ctx context.Context,
	flowClient *client.Client,
	address string,
	skString string,
) (result *flow.TransactionResult, err error) {
	txScript := util.ParseCadenceTemplate("../../../transactions/pause/create_new_pauser.cdc")

	account, err := flowClient.GetAccount(ctx, flow.HexToAddress(address))
	if err != nil {
		return
	}

	key1 := account.Keys[0]

	privateKey, err := crypto.DecodePrivateKeyHex(crypto.ECDSA_P256, skString)
	if err != nil {
		return
	}

	key1Signer := crypto.NewInMemorySigner(privateKey, key1.HashAlgo)

	referenceBlock, err := flowClient.GetLatestBlock(ctx, true)
	if err != nil {
		return
	}

	tx := flow.NewTransaction().
		SetScript(txScript).
		SetGasLimit(100).
		SetProposalKey(account.Address, key1.Index, key1.SequenceNumber).
		SetPayer(account.Address).
		SetReferenceBlockID(referenceBlock.ID).
		AddAuthorizer(account.Address)

	err = tx.AddArgument(cadence.Address(flow.HexToAddress(address)))
	if err != nil {
		return
	}

	err = tx.SignEnvelope(account.Address, key1.Index, key1Signer)
	if err != nil {
		return
	}

	err = flowClient.SendTransaction(ctx, *tx)
	if err != nil {
		return
	}

	result, err = util.WaitForSeal(ctx, flowClient, tx.ID())
	if err != nil {
		return
	}

	return
}

func SetPauserCapability(
	ctx context.Context,
	flowClient *client.Client,
	pauserAddress string,
	ownerAddress string,
	skString string,
) (result *flow.TransactionResult, err error) {
	txScript := util.ParseCadenceTemplate("../../../transactions/owner/set_pause_cap.cdc")

	account, err := flowClient.GetAccount(ctx, flow.HexToAddress(ownerAddress))
	if err != nil {
		return
	}

	key1 := account.Keys[0]

	privateKey, err := crypto.DecodePrivateKeyHex(crypto.ECDSA_P256, skString)
	if err != nil {
		return
	}

	key1Signer := crypto.NewInMemorySigner(privateKey, key1.HashAlgo)

	referenceBlock, err := flowClient.GetLatestBlock(ctx, true)
	if err != nil {
		return
	}

	tx := flow.NewTransaction().
		SetScript(txScript).
		SetGasLimit(100).
		SetProposalKey(account.Address, key1.Index, key1.SequenceNumber).
		SetPayer(account.Address).
		SetReferenceBlockID(referenceBlock.ID).
		AddAuthorizer(account.Address)

	err = tx.AddArgument(cadence.Address(flow.HexToAddress(pauserAddress)))
	if err != nil {
		return
	}

	err = tx.AddArgument(cadence.Path{Domain: "public", Identifier: "UsdcPauseCapReceiver"})
	if err != nil {
		return
	}

	err = tx.SignEnvelope(account.Address, key1.Index, key1Signer)
	if err != nil {
		return
	}

	err = flowClient.SendTransaction(ctx, *tx)
	if err != nil {
		return
	}

	result, err = util.WaitForSeal(ctx, flowClient, tx.ID())
	if err != nil {
		return
	}

	return
}

func PauseOrUnpauseContract(
	ctx context.Context,
	flowClient *client.Client,
	pauserAddress string,
	skString string,
	pause uint,
) (result *flow.TransactionResult, err error) {

	var txScript []byte

	if pause == 1 {
		txScript = util.ParseCadenceTemplate("../../../transactions/pause/pause_contract.cdc")
	} else {
		txScript = util.ParseCadenceTemplate("../../../transactions/pause/unpause_contract.cdc")
	}

	account, err := flowClient.GetAccount(ctx, flow.HexToAddress(pauserAddress))
	if err != nil {
		return
	}

	key1 := account.Keys[0]

	privateKey, err := crypto.DecodePrivateKeyHex(crypto.ECDSA_P256, skString)
	if err != nil {
		return
	}

	key1Signer := crypto.NewInMemorySigner(privateKey, key1.HashAlgo)

	referenceBlock, err := flowClient.GetLatestBlock(ctx, true)
	if err != nil {
		return
	}

	tx := flow.NewTransaction().
		SetScript(txScript).
		SetGasLimit(100).
		SetProposalKey(account.Address, key1.Index, key1.SequenceNumber).
		SetPayer(account.Address).
		SetReferenceBlockID(referenceBlock.ID).
		AddAuthorizer(account.Address)

	err = tx.SignEnvelope(account.Address, key1.Index, key1Signer)
	if err != nil {
		return
	}

	err = flowClient.SendTransaction(ctx, *tx)
	if err != nil {
		return
	}

	result, err = util.WaitForSeal(ctx, flowClient, tx.ID())
	if err != nil {
		return
	}

	return
}

func GetPaused(ctx context.Context, flowClient *client.Client) (cadence.Bool, error) {
	script := util.ParseCadenceTemplate("../../../scripts/get_paused.cdc")

	value, err := flowClient.ExecuteScriptAtLatestBlock(ctx, script, []cadence.Value{})
	if err != nil {
		return false, err
	}

	paused := value.(cadence.Bool)
	return paused, err
}
