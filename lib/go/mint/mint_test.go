package mint

import (
	"testing"

	"github.com/bjartek/go-with-the-flow/gwtf"
	"github.com/stretchr/testify/assert"
)

func TestCreateMinter(t *testing.T) {
	g := gwtf.NewGoWithTheFlow("../../../flow.json")
	err := CreateMinter(g, "minter")
	assert.NoError(t, err)

	_, err = GetMinterUUID(g, "minter")
	assert.NoError(t, err)
}

func TestCreateMinterController(t *testing.T) {
	g := gwtf.NewGoWithTheFlow("../../../flow.json")
	err := CreateMinterController(g, "minterController1")
	assert.NoError(t, err)

	_, err = GetMinterControllerUUID(g, "minterController1")
	assert.NoError(t, err)
}
