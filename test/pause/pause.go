package main

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
) (*flow.TransactionResult, error) {
	txScript := util.ParseCadenceTemplate("../../transactions/pause/create_new_pauser.cdc")

	account, err := flowClient.GetAccount(ctx, flow.HexToAddress(address))
	if err != nil {
		return nil, err
	}

	key1 := account.Keys[0]

	privateKey, err := crypto.DecodePrivateKeyHex(crypto.ECDSA_P256, skString)
	if err != nil {
		return nil, err
	}

	key1Signer := crypto.NewInMemorySigner(privateKey, key1.HashAlgo)

	referenceBlock, err := flowClient.GetLatestBlock(ctx, true)
	if err != nil {
		return nil, err
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
		return nil, err
	}

	err = flowClient.SendTransaction(ctx, *tx)
	if err != nil {
		return nil, err
	}

	result, err := util.WaitForSeal(ctx, flowClient, tx.ID())
	if err != nil {
		return nil, err
	}

	return result, nil
}

func SetPauserCapability(
	ctx context.Context,
	flowClient *client.Client,
	pauserAddress string,
	ownerAddress string,
	skString string,
) (*flow.TransactionResult, error) {
	txScript := util.ParseCadenceTemplate("../../transactions/owner/set_pause_cap.cdc")

	account, err := flowClient.GetAccount(ctx, flow.HexToAddress(ownerAddress))
	if err != nil {
		return nil, err
	}

	key1 := account.Keys[0]

	privateKey, err := crypto.DecodePrivateKeyHex(crypto.ECDSA_P256, skString)
	if err != nil {
		return nil, err
	}

	key1Signer := crypto.NewInMemorySigner(privateKey, key1.HashAlgo)

	referenceBlock, err := flowClient.GetLatestBlock(ctx, true)
	if err != nil {
		return nil, err
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
		return nil, err
	}

	err = tx.AddArgument(cadence.Path{Domain: "public", Identifier: "UsdcPauseCapReceiver"})
	if err != nil {
		return nil, err
	}

	err = tx.SignEnvelope(account.Address, key1.Index, key1Signer)
	if err != nil {
		return nil, err
	}

	err = flowClient.SendTransaction(ctx, *tx)
	if err != nil {
		return nil, err
	}

	result, err := util.WaitForSeal(ctx, flowClient, tx.ID())
	if err != nil {
		return nil, err
	}

	return result, nil
}
