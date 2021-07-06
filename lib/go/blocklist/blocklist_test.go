package blocklist

import (
	"log"
	"testing"

	"github.com/bjartek/go-with-the-flow/gwtf"
	util "github.com/flow-usdc/flow-usdc"
	"github.com/flow-usdc/flow-usdc/vault"
	"github.com/stretchr/testify/assert"
)

func TestGetUUID(t *testing.T) {
	g := gwtf.NewGoWithTheFlow("../../../flow.json")

	err := vault.AddVaultToAccount(g, "vaulted-account")
	assert.NoError(t, err)

	uuid, err := util.GetVaultUUID(g, "vaulted-account")
	assert.NoError(t, err)
	log.Print("uuid: ", uuid.String())
}

func TestCreateBlocklister(t *testing.T) {
	g := gwtf.NewGoWithTheFlow("../../../flow.json")
	err := CreateBlocklister(g, "blocklister")
	assert.NoError(t, err)
}

func TestSetBlocklistCapability(t *testing.T) {
	g := gwtf.NewGoWithTheFlow("../../../flow.json")
	err := SetBlocklistCapability(g, "blocklister", "owner")
	assert.NoError(t, err)
}
