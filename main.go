package main

import (
	"context"
	"io/ioutil"

	"github.com/onflow/cadence"
	"github.com/onflow/flow-go-sdk"
	"github.com/onflow/flow-go-sdk/client"
	"github.com/onflow/flow-go-sdk/crypto"
)

// TODO: Better sk handling here
func AddVaultToAccount(
	ctx context.Context,
	flowClient *client.Client,
	account *flow.Account,
	skString string,
) error {
	txScript, err := ioutil.ReadFile("./transactions/setup_account.cdc")

	key1 := account.Keys[0]

	privateKey, err := crypto.DecodePrivateKeyHex(crypto.ECDSA_P256, skString)
	key1Signer := crypto.NewInMemorySigner(privateKey, key1.HashAlgo)

	referenceBlock, err := flowClient.GetLatestBlock(ctx, true)

	tx := flow.NewTransaction().
		SetScript(txScript).
		SetGasLimit(100).
		SetProposalKey(account.Address, key1.Index, key1.SequenceNumber).
		SetPayer(account.Address).
		SetReferenceBlockID(referenceBlock.ID).
		AddAuthorizer(account.Address)

	err = tx.SignEnvelope(account.Address, key1.Index, key1Signer)

	err = flowClient.SendTransaction(ctx, *tx)
	return err
}

func GetSupply(ctx context.Context, flowClient *client.Client) (cadence.UFix64, error) {
	script, err := ioutil.ReadFile("./contracts/scripts/get_supply.cdc")

	value, err := flowClient.ExecuteScriptAtLatestBlock(ctx, script, nil)

	supply := value.(cadence.UFix64)
	return supply, err
}

func GetBalance(ctx context.Context, flowClient *client.Client, address flow.Address) (cadence.UFix64, error) {
	script, err := ioutil.ReadFile("./contracts/scripts/get_balance.cdc")

	value, err := flowClient.ExecuteScriptAtLatestBlock(ctx, script, []cadence.Value{
		cadence.Address(address),
	})
	if err != nil {
		return 0, err
	}

	balance := value.(cadence.UFix64)
	return balance, nil
}

func TransferTokens(
	ctx context.Context,
	flowClient *client.Client,
	amount cadence.UFix64,
	from *flow.Account,
	toAddress flow.Address,
	skString string,
) (*flow.TransactionResult, error) {
	txScript, err := ioutil.ReadFile("./transactions/transfer_tokens.cdc")
	if err != nil {
		return nil, err
	}

	privateKey, err := crypto.DecodePrivateKeyHex(crypto.ECDSA_P256, skString)
	if err != nil {
		return nil, err
	}

	key1 := from.Keys[0]
	key1Signer := crypto.NewInMemorySigner(privateKey, key1.HashAlgo)

	referenceBlock, err := flowClient.GetLatestBlock(ctx, true)
	if err != nil {
		return nil, err
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
		return nil, err
	}

	err = tx.AddArgument(cadence.Address(toAddress))
	if err != nil {
		return nil, err
	}

	err = tx.SignEnvelope(from.Address, key1.Index, key1Signer)
	if err != nil {
		return nil, err
	}

	err = flowClient.SendTransaction(ctx, *tx)
	if err != nil {
		return nil, err
	}

	result, err := flowClient.GetTransactionResult(ctx, tx.ID())
	return result, err
}

func MintTokens(
	ctx context.Context,
	flowClient *client.Client,
	mintingAccount *flow.Account,
	amount cadence.UFix64,
	skString string,
) (*flow.TransactionResult, error) {
	txScript, err := ioutil.ReadFile("./transactions/mint_tokens.cdc")
	if err != nil {
		return nil, err
	}

	privateKey, err := crypto.DecodePrivateKeyHex(crypto.ECDSA_P256, skString)
	if err != nil {
		return nil, err
	}

	key1 := mintingAccount.Keys[0]
	key1Signer := crypto.NewInMemorySigner(privateKey, key1.HashAlgo)

	referenceBlock, err := flowClient.GetLatestBlock(ctx, true)
	if err != nil {
		return nil, err
	}

	tx := flow.NewTransaction().
		SetScript(txScript).
		SetGasLimit(100).
		SetProposalKey(mintingAccount.Address, key1.Index, key1.SequenceNumber).
		SetPayer(mintingAccount.Address).
		SetReferenceBlockID(referenceBlock.ID).
		AddAuthorizer(mintingAccount.Address)

	err = tx.AddArgument(cadence.Address(mintingAccount.Address))
	if err != nil {
		return nil, err
	}

	err = tx.AddArgument(cadence.UFix64(amount))
	if err != nil {
		return nil, err
	}

	err = tx.SignEnvelope(mintingAccount.Address, key1.Index, key1Signer)
	if err != nil {
		return nil, err
	}

	err = flowClient.SendTransaction(ctx, *tx)
	if err != nil {
		return nil, err
	}

	result, err := flowClient.GetTransactionResult(ctx, tx.ID())
	return result, err
}

func BurnTokens(
	ctx context.Context,
	flowClient *client.Client,
	burningAccount *flow.Account,
	amount cadence.UFix64,
	skString string,
) (*flow.TransactionResult, error) {
	txScript, err := ioutil.ReadFile("./transactions/burn_tokens.cdc")
	if err != nil {
		return nil, err
	}

	privateKey, err := crypto.DecodePrivateKeyHex(crypto.ECDSA_P256, skString)
	if err != nil {
		return nil, err
	}

	key1 := burningAccount.Keys[0]
	key1Signer := crypto.NewInMemorySigner(privateKey, key1.HashAlgo)

	referenceBlock, err := flowClient.GetLatestBlock(ctx, true)
	if err != nil {
		return nil, err
	}

	tx := flow.NewTransaction().
		SetScript(txScript).
		SetGasLimit(100).
		SetProposalKey(burningAccount.Address, key1.Index, key1.SequenceNumber).
		SetPayer(burningAccount.Address).
		SetReferenceBlockID(referenceBlock.ID).
		AddAuthorizer(burningAccount.Address)

	err = tx.AddArgument(cadence.UFix64(amount))
	if err != nil {
		return nil, err
	}

	err = tx.SignEnvelope(burningAccount.Address, key1.Index, key1Signer)
	if err != nil {
		return nil, err
	}

	err = flowClient.SendTransaction(ctx, *tx)
	if err != nil {
		return nil, err
	}

	result, err := flowClient.GetTransactionResult(ctx, tx.ID())
	return result, err
}
