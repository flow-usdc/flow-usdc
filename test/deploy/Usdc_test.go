package usdc 

import (
	"os"
	"testing"

	// "github.com/onflow/cadence"
    "github.com/flow-usdc/flow-usdc"
	"github.com/stretchr/testify/assert"
)

func TestDeployUSDCContract(t *testing.T) {
	ctx, flowClient := util.SetupTestEnvironment(t)

	ownerAddress := os.Getenv("TOKEN_ACCOUNT_ADDRESS")
	skFT := os.Getenv("TOKEN_ACCOUNT_KEYS")

	result, err := DeployUSDCContract(ctx, flowClient, ownerAddress, skFT)
	assert.NoError(t, err)
	t.Log(result.Events)
}

func TestUSDCTotalSupplyInOwnerVault(t *testing.T) {
	ctx, flowClient := util.SetupTestEnvironment(t)
	supply, err := GetTotalSupply(ctx, flowClient)
	assert.NoError(t, err)
    assert.Equal(t, "10000.00000000", supply.String());

    ownerAddress := os.Getenv("TOKEN_ACCOUNT_ADDRESS")
    balance, err := util.GetBalance(ctx, flowClient, ownerAddress)
    assert.NoError(t, err)
    assert.Equal(t, "10000.00000000", balance.String());
}
