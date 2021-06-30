package vault

import (
	"context"

	util "github.com/flow-usdc/flow-usdc"
	"github.com/onflow/cadence"
	"github.com/onflow/flow-go-sdk"
	"github.com/onflow/flow-go-sdk/client"
	"github.com/onflow/flow-go-sdk/crypto"
)

func AddVaultToAccount(
	ctx context.Context,
	flowClient *client.Client,
	address string,
	skString string,
) (result *flow.TransactionResult, err error) {
	txScript := util.ParseCadenceTemplate("../../../transactions/create_vault.cdc")

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

func TransferTokens(
	ctx context.Context,
	flowClient *client.Client,
	amount cadence.UFix64,
	fromAddress string,
	toAddress string,
	skString string,
) (result *flow.TransactionResult, err error) {
	txScript := util.ParseCadenceTemplate("../../../transactions/transfer_USDC.cdc")

	privateKey, err := crypto.DecodePrivateKeyHex(crypto.ECDSA_P256, skString)
	if err != nil {
		return
	}

	from, err := flowClient.GetAccount(ctx, flow.HexToAddress(fromAddress))
	if err != nil {
		return
	}

	key1 := from.Keys[0]
	key1Signer := crypto.NewInMemorySigner(privateKey, key1.HashAlgo)

	referenceBlock, err := flowClient.GetLatestBlock(ctx, true)
	if err != nil {
		return
	}

	tx := flow.NewTransaction().
		SetScript(txScript).
		SetGasLimit(100).
		SetProposalKey(from.Address, key1.Index, key1.SequenceNumber).
		SetPayer(from.Address).
		SetReferenceBlockID(referenceBlock.ID).
		AddAuthorizer(from.Address)

	err = tx.AddArgument(cadence.UFix64(amount))
	if err != nil {
		return
	}

	err = tx.AddArgument(cadence.Address(flow.HexToAddress(toAddress)))
	if err != nil {
		return
	}

	err = tx.SignEnvelope(from.Address, key1.Index, key1Signer)
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
