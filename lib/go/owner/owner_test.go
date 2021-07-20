package owner

import (
	"fmt"
	"strconv"
	"testing"

	"github.com/bjartek/go-with-the-flow/gwtf"
	util "github.com/flow-usdc/flow-usdc"

	"github.com/stretchr/testify/assert"
)

func TestGetBytes(t *testing.T) {
	g := gwtf.NewGoWithTheFlow("../../../flow.json")
	signable, err := util.GetSignableDataFromScript(g, "configureMinterController", uint64(123), uint64(345))
	fmt.Println("signable: ", signable)
	assert.NoError(t, err)
}

func TestMultiSig_NewTxConfigureMinter(t *testing.T) {
	g := gwtf.NewGoWithTheFlow("../../../flow.json")
	events, err := MultiSig_NewConfigureMinterController(g, uint64(111), uint64(222), 1, "owner")
	assert.NoError(t, err)

	txIndexStr := events[0].Fields["txIndex"]
	txIndex, err := strconv.ParseUint(txIndexStr.(string), 10, 64)
	fmt.Println("txindex: ", txIndex)
}

func TestMultiSig_ExecuteTx(t *testing.T) {
	g := gwtf.NewGoWithTheFlow("../../../flow.json")
	event, err := MultiSig_MasterMinterExecuteTx(g, 1, "owner")
	assert.NoError(t, err)
	fmt.Println("Execute Event: \n", event)
}
