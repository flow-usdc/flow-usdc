package util

import (
	"bytes"
	"encoding/hex"
	"errors"
	"io/ioutil"
	"testing"
	"time"

	"text/template"

	"github.com/bjartek/go-with-the-flow/gwtf"
	"github.com/onflow/cadence"
	"github.com/onflow/flow-go-sdk"
	"github.com/onflow/flow-go-sdk/crypto"
	"github.com/stretchr/testify/assert"
)

// Useful multisig accounts
// These are named by the weights
// i.e. Account500_1 has a weight of 500.0
const Acct1000 = "w-1000"
const Acct500_1 = "w-500-1"
const Acct500_2 = "w-500-2"
const Acct250_1 = "w-250-1"
const Acct250_2 = "w-250-2"

type Addresses struct {
	FungibleToken      string
	ExampleToken       string
	FiatTokenInterface string
	FiatToken          string
	OnChainMultiSig    string
}

type TestEvent struct {
	Name   string
	Fields map[string]string
}

var addresses Addresses

func ParseCadenceTemplate(templatePath string) []byte {
	fb, err := ioutil.ReadFile(templatePath)
	if err != nil {
		panic(err)
	}

	tmpl, err := template.New("Template").Parse(string(fb))
	if err != nil {
		panic(err)
	}

	// Addresss for emulator are
	addresses = Addresses{"ee82856bf20e2aa6", "01cf0e2f2f715450", "01cf0e2f2f715450", "01cf0e2f2f715450", "01cf0e2f2f715450"}
	// addresses = Addresses{os.Getenv("FUNGIBLE_TOKEN_ADDRESS"), os.Getenv("TOKEN_ACCOUNT_ADDRESS"), os.Getenv("TOKEN_ACCOUNT_ADDRESS"), os.Getenv("TOKEN_ACCOUNT_ADDRESS"), os.Getenv("TOKEN_ACCOUNT_ADDRESS")}
	buf := &bytes.Buffer{}
	err = tmpl.Execute(buf, addresses)
	if err != nil {
		panic(err)
	}

	return buf.Bytes()
}

func ParseTestEvents(events []flow.Event) (formatedEvents []*gwtf.FormatedEvent) {
	for _, e := range events {
		formatedEvents = append(formatedEvents, gwtf.ParseEvent(e, uint64(0), time.Now(), nil))
	}
	return
}

func NewExpectedEvent(name string) TestEvent {
	return TestEvent{
		Name:   "A." + addresses.FiatToken + ".FiatToken." + name,
		Fields: map[string]string{},
	}
}

func (te TestEvent) AddField(fieldName string, fieldValue string) TestEvent {
	te.Fields[fieldName] = fieldValue
	return te
}

func (te TestEvent) AssertHasKey(t *testing.T, event *gwtf.FormatedEvent, key string) {
	assert.Equal(t, event.Name, te.Name)
	_, exist := event.Fields[key]
	assert.Equal(t, true, exist)
}

func (te TestEvent) AssertEqual(t *testing.T, event *gwtf.FormatedEvent) {
	assert.Equal(t, event.Name, te.Name)
	assert.Equal(t, len(te.Fields), len(event.Fields))
	for k := range te.Fields {
		assert.Equal(t, te.Fields[k], event.Fields[k])
	}
}

func GetAccountAddr(g *gwtf.GoWithTheFlow, name string) string {
	address := cadence.BytesToAddress(g.Accounts[name].Address.Bytes())
	return address.String()
}

func ReadCadenceCode(ContractPath string) []byte {
	b, err := ioutil.ReadFile(ContractPath)
	if err != nil {
		panic(err)
	}
	return b
}

func GetTotalSupply(g *gwtf.GoWithTheFlow) (result cadence.UFix64, err error) {
	filename := "../../../scripts/contract/get_total_supply.cdc"
	script := ParseCadenceTemplate(filename)
	r, err := g.ScriptFromFile(filename, script).RunReturns()
	result = r.(cadence.UFix64)
	return
}

func GetBalance(g *gwtf.GoWithTheFlow, account string) (result cadence.UFix64, err error) {
	filename := "../../../scripts/vault/get_balance.cdc"
	script := ParseCadenceTemplate(filename)
	value, err := g.ScriptFromFile(filename, script).AccountArgument(account).RunReturns()
	if err != nil {
		return
	}
	result = value.(cadence.UFix64)
	return
}

func GetVaultUUID(g *gwtf.GoWithTheFlow, account string) (r uint64, err error) {
	filename := "../../../scripts/vault/get_vault_uuid.cdc"
	script := ParseCadenceTemplate(filename)
	value, err := g.ScriptFromFile(filename, script).AccountArgument(account).RunReturns()
	if err != nil {
		return
	}
	r, ok := value.ToGoValue().(uint64)
	if !ok {
		err = errors.New("returned not uint64")
	}
	return
}

func ConvertCadenceByteArray(a cadence.Value) (b []uint8) {
	// type assertion of interface
	i := a.ToGoValue().([]interface{})

	for _, e := range i {
		// type assertion of uint8
		b = append(b, e.(uint8))
	}
	return

}

func ConvertCadenceStringArray(a cadence.Value) (b []string) {
	// type assertion of interface
	i := a.ToGoValue().([]interface{})

	for _, e := range i {
		b = append(b, e.(string))
	}
	return
}

// Multisig utility functions

// Signing payload offline
func SignPayloadOffline(g *gwtf.GoWithTheFlow, message []byte, signingAcct string) (sig string, err error) {
	s := g.Accounts[signingAcct]
	signer := crypto.NewInMemorySigner(s.PrivateKey, s.HashAlgo)
	message = append(flow.UserDomainTag[:], message...)
	sigbytes, err := signer.Sign(message)
	if err != nil {
		return
	}

	sig = hex.EncodeToString(sigbytes)
	return
}

func GetSignableDataFromScript(
	g *gwtf.GoWithTheFlow,
	txIndex uint64,
	method string,
	args ...cadence.Value,
) (signable []byte, err error) {
	filename := "../../../scripts/calc_signable_data.cdc"
	script := ParseCadenceTemplate(filename)

	ctxIndex, err := g.ScriptFromFile(filename, script).Argument(cadence.NewOptional(cadence.UInt64(txIndex))).RunReturns()
	if err != nil {
		return
	}
	signable = append(signable, ConvertCadenceByteArray(ctxIndex)...)
	cMethod, err := g.ScriptFromFile(filename, script).Argument(cadence.NewOptional(cadence.String(method))).RunReturns()
	if err != nil {
		return
	}
	signable = append(signable, ConvertCadenceByteArray(cMethod)...)

	for _, arg := range args {
		var b cadence.Value
		b, err = g.ScriptFromFile(filename, script).Argument(cadence.NewOptional(arg)).RunReturns()
		if err != nil {
			return nil, err
		}
		signable = append(signable, ConvertCadenceByteArray(b)...)
	}
	return
}

func MultiSig_NewPayload(
	g *gwtf.GoWithTheFlow,
	filePath string,
	sig string,
	txIndex uint64,
	method string,
	args []cadence.Value,
	signerAcct string,
	resourceAcct string,
) (events []*gwtf.FormatedEvent, err error) {
	txFilename := "../../../transactions/" + filePath
	txScript := ParseCadenceTemplate(txFilename)

	signerPubKey := g.Accounts[signerAcct].PrivateKey.PublicKey().String()
	e, err := g.TransactionFromFile(txFilename, txScript).
		SignProposeAndPayAs(signerAcct).
		StringArgument(sig).
		UInt64Argument(txIndex).
		StringArgument(method).
		Argument(cadence.NewArray(args)).
		StringArgument(signerPubKey[2:]).
		AccountArgument(resourceAcct).
		Run()
	events = ParseTestEvents(e)
	return
}

func MultiSig_AddPayloadSignature(
	g *gwtf.GoWithTheFlow,
	filePath string,
	sig string,
	txIndex uint64,
	signerAcct string,
	resourceAcct string,
) (events []*gwtf.FormatedEvent, err error) {
	txFilename := "../../../transactions/" + filePath
	txScript := ParseCadenceTemplate(txFilename)

	signerPubKey := g.Accounts[signerAcct].PrivateKey.PublicKey().String()
	e, err := g.TransactionFromFile(txFilename, txScript).
		SignProposeAndPayAs(signerAcct).
		StringArgument(sig).
		UInt64Argument(txIndex).
		StringArgument(signerPubKey[2:]).
		AccountArgument(resourceAcct).
		Run()
	events = ParseTestEvents(e)
	return
}

func MultiSig_ExecuteTx(
	g *gwtf.GoWithTheFlow,
	filePath string,
	index uint64,
	payerAcct string,
	resourceAcct string,
) (events []*gwtf.FormatedEvent, err error) {
	txFilename := "../../../transactions/" + filePath
	txScript := ParseCadenceTemplate(txFilename)

	e, err := g.TransactionFromFile(txFilename, txScript).
		SignProposeAndPayAs(payerAcct).
		AccountArgument(resourceAcct).
		UInt64Argument(index).
		Run()
	events = ParseTestEvents(e)
	return
}

func GetStoreKeys(g *gwtf.GoWithTheFlow, filePath string, account string) (result []string, err error) {
	filename := "../../../scripts/" + filePath
	script := ParseCadenceTemplate(filename)
	value, err := g.ScriptFromFile(filename, script).AccountArgument(account).RunReturns()
	if err != nil {
		return
	}
	result = ConvertCadenceStringArray(value)
	return
}

func GetKeyWeight(g *gwtf.GoWithTheFlow, filePath string, resourceAcct string, signerAcct string) (result cadence.UFix64, err error) {
	filename := "../../../scripts/" + filePath
	script := ParseCadenceTemplate(filename)
	signerPubKey := g.Accounts[signerAcct].PrivateKey.PublicKey().String()[2:]
	value, err := g.ScriptFromFile(filename, script).
		AccountArgument(resourceAcct).
		StringArgument(signerPubKey).
		RunReturns()
	if err != nil {
		return
	}
	result = value.(cadence.UFix64)
	return
}

func GetTxIndex(g *gwtf.GoWithTheFlow, filePath string, account string) (result uint64, err error) {
	filename := "../../../scripts/" + filePath
	script := ParseCadenceTemplate(filename)
	value, err := g.ScriptFromFile(filename, script).AccountArgument(account).RunReturns()
	if err != nil {
		return
	}
	result = value.ToGoValue().(uint64)
	return
}
