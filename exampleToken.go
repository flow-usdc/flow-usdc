package main

import (
	"context"
	"log"

	"github.com/onflow/cadence"
	"github.com/onflow/flow-go-sdk"
	"github.com/onflow/flow-go-sdk/client"
	"github.com/onflow/flow-go-sdk/crypto"
)


// TODO: Better sk handling here
func AddVaultToAccount(
	ctx context.Context,
	flowClient *client.Client,
	address string,
	skString string,
) (*flow.TransactionResult, error) {
	txScript := ParseCadenceTemplate("./transactions/setup_account.cdc")

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

	result, err := WaitForSeal(ctx, flowClient, tx.ID())
	if err != nil {
		return nil, err
	}

	return result, nil
}

func GetSupply(ctx context.Context, flowClient *client.Client) (cadence.UFix64, error) {
	script := ParseCadenceTemplate("./contracts/scripts/get_supply.cdc")
	log.Println(string(script))

	value, err := flowClient.ExecuteScriptAtLatestBlock(ctx, script, nil)

	supply := value.(cadence.UFix64)
	return supply, err
}

func GetBalance(ctx context.Context, flowClient *client.Client, address string) (cadence.UFix64, error) {
	script := ParseCadenceTemplate("./contracts/scripts/get_balance.cdc")

	flowAddress := flow.HexToAddress(address)
	value, err := flowClient.ExecuteScriptAtLatestBlock(ctx, script, []cadence.Value{
		cadence.Address(flowAddress),
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
	fromAddress string,
	toAddress string,
	skString string,
) (*flow.TransactionResult, error) {
	txScript := ParseCadenceTemplate("./transactions/transfer_tokens.cdc")

	privateKey, err := crypto.DecodePrivateKeyHex(crypto.ECDSA_P256, skString)
	if err != nil {
		return nil, err
	}

	from, err := flowClient.GetAccount(ctx, flow.HexToAddress(fromAddress))
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

	err = tx.AddArgument(cadence.Address(flow.HexToAddress(toAddress)))
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

	result, err := WaitForSeal(ctx, flowClient, tx.ID())
	if err != nil {
		return nil, err
	}

	return result, err
}

func MintTokens(
	ctx context.Context,
	flowClient *client.Client,
	mintingAccountAddress string,
	amount cadence.UFix64,
	skString string,
) (*flow.TransactionResult, error) {
	txScript := ParseCadenceTemplate("./transactions/mint_tokens.cdc")

	address := flow.HexToAddress(mintingAccountAddress)
	mintingAccount, err := flowClient.GetAccount(ctx, address)
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

	result, err := WaitForSeal(ctx, flowClient, tx.ID())
	if err != nil {
		return nil, err
	}

	return result, err
}

func BurnTokens(
	ctx context.Context,
	flowClient *client.Client,
	burningAccountAddress string,
	amount cadence.UFix64,
	skString string,
) (*flow.TransactionResult, error) {
	txScript := ParseCadenceTemplate("./transactions/burn_tokens.cdc")

	address := flow.HexToAddress(burningAccountAddress)
	burningAccount, err := flowClient.GetAccount(ctx, address)
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

	result, err := WaitForSeal(ctx, flowClient, tx.ID())
	if err != nil {
		return nil, err
	}

	return result, err
}

func CreateAdmin(
	ctx context.Context,
	flowClient *client.Client,
	oldAdminAddress string,
	newAdminAddress string,
	skOld string,
	skNew string,
) (*flow.TransactionResult, error) {
	txScript := ParseCadenceTemplate("./transactions/create_admin.cdc")

	oldPrivateKey, err := crypto.DecodePrivateKeyHex(crypto.ECDSA_P256, skOld)
	if err != nil {
		return nil, err
	}

	oldAdmin, err := flowClient.GetAccount(ctx, flow.HexToAddress(oldAdminAddress))
	if err != nil {
		return nil, err
	}

	oldKeys := oldAdmin.Keys[0]
	oldKeySigner := crypto.NewInMemorySigner(oldPrivateKey, oldKeys.HashAlgo)

	newPrivateKey, err := crypto.DecodePrivateKeyHex(crypto.ECDSA_P256, skNew)
	if err != nil {
		return nil, err
	}

	newAdmin, err := flowClient.GetAccount(ctx, flow.HexToAddress(newAdminAddress))
	if err != nil {
		return nil, err
	}

	newKeys := newAdmin.Keys[0]
	newKeySigner := crypto.NewInMemorySigner(newPrivateKey, newKeys.HashAlgo)

	referenceBlock, err := flowClient.GetLatestBlock(ctx, true)
	if err != nil {
		return nil, err
	}

	tx := flow.NewTransaction().
		SetScript(txScript).
		SetGasLimit(100).
		SetProposalKey(oldAdmin.Address, oldKeys.Index, oldKeys.SequenceNumber).
		SetPayer(newAdmin.Address).
		SetReferenceBlockID(referenceBlock.ID).
		AddAuthorizer(oldAdmin.Address).
		AddAuthorizer(newAdmin.Address)

	err = tx.SignPayload(oldAdmin.Address, oldKeys.Index, oldKeySigner)
	if err != nil {
		return nil, err
	}

	// Payer always signs last
	err = tx.SignEnvelope(newAdmin.Address, newKeys.Index, newKeySigner)
	if err != nil {
		return nil, err
	}

	err = flowClient.SendTransaction(ctx, *tx)
	if err != nil {
		return nil, err
	}

	result, err := WaitForSeal(ctx, flowClient, tx.ID())
	if err != nil {
		return nil, err
	}

	return result, err
}
