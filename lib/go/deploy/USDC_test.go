package deploy

import (
	"os"
	"testing"

	"github.com/bjartek/go-with-the-flow/v2/gwtf"
	util "github.com/flow-usdc/flow-usdc"
	"github.com/stretchr/testify/assert"
)

func TestFiatTokenTotalSupplyInOwnerVault(t *testing.T) {
	g := gwtf.NewGoWithTheFlow(util.FlowJSON, os.Getenv("NETWORK"), false, 1)
	supply, err := util.GetTotalSupply(g)
	assert.NoError(t, err)
	assert.Equal(t, "10000.00000000", supply.String())

	balance, err := util.GetBalance(g, "owner")
	assert.NoError(t, err)
	assert.Equal(t, "10000.00000000", balance.String())
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
