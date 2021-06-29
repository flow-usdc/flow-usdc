package deploy

import (
	"context"
	"encoding/hex"

	util "github.com/flow-usdc/flow-usdc"
	"github.com/onflow/cadence"
	"github.com/onflow/flow-go-sdk"
	"github.com/onflow/flow-go-sdk/client"
	"github.com/onflow/flow-go-sdk/crypto"
)

func DeployUSDCContract(
	ctx context.Context,
	flowClient *client.Client,
	ownerAcctAddr string,
	skString string,
) (*flow.TransactionResult, error) {

	code := util.ParseCadenceTemplate("../../contracts/USDC.cdc")
	encodedStr := hex.EncodeToString(code)
	txScript := util.ParseCadenceTemplate("../../transactions/deploy_contract_with_auth.cdc")

	address := flow.HexToAddress(ownerAcctAddr)
	ownerAccount, err := flowClient.GetAccount(ctx, address)
	if err != nil {
		return nil, err
	}

	privateKey, err := crypto.DecodePrivateKeyHex(crypto.ECDSA_P256, skString)
	if err != nil {
		return nil, err
	}

	key1 := ownerAccount.Keys[0]
	key1Signer := crypto.NewInMemorySigner(privateKey, key1.HashAlgo)

	referenceBlock, err := flowClient.GetLatestBlock(ctx, true)
	if err != nil {
		return nil, err
	}

	tx := flow.NewTransaction().
		SetScript(txScript).
		SetGasLimit(100).
		SetProposalKey(ownerAccount.Address, key1.Index, key1.SequenceNumber).
		SetPayer(ownerAccount.Address).
		SetReferenceBlockID(referenceBlock.ID).
		AddAuthorizer(ownerAccount.Address)

	err = tx.AddArgument(cadence.String("USDC"))
	if err != nil {
		return nil, err
	}

	err = tx.AddArgument(cadence.String(encodedStr))
	if err != nil {
		return nil, err
	}

	err = tx.SignEnvelope(ownerAccount.Address, key1.Index, key1Signer)
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

	return result, err
}

func GetTotalSupply(ctx context.Context, flowClient *client.Client) (cadence.UFix64, error) {
	script := util.ParseCadenceTemplate("../../../contracts/scripts/get_total_supply.cdc")
	value, err := flowClient.ExecuteScriptAtLatestBlock(ctx, script, nil)
	supply := value.(cadence.UFix64)
	return supply, err
}
