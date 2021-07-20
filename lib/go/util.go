package util

import (
	"bytes"
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
	filename := "../../../scripts/get_total_supply.cdc"
	script := ParseCadenceTemplate(filename)
	r, err := g.ScriptFromFile(filename, script).RunReturns()
	result = r.(cadence.UFix64)
	return
}

func GetBalance(g *gwtf.GoWithTheFlow, account string) (result cadence.UFix64, err error) {
	filename := "../../../scripts/get_balance.cdc"
	script := ParseCadenceTemplate(filename)
	value, err := g.ScriptFromFile(filename, script).AccountArgument(account).RunReturns()
	if err != nil {
		return
	}
	result = value.(cadence.UFix64)
	return
}

func GetVaultUUID(g *gwtf.GoWithTheFlow, account string) (r uint64, err error) {
	filename := "../../../scripts/get_vault_uuid.cdc"
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

// Multisig utility functions

// Signing payload offline
func SignPayloadOffline(g *gwtf.GoWithTheFlow, message []byte, signingAcct string) (sig []byte, err error) {
	s := g.Accounts[signingAcct]
	signer := crypto.NewInMemorySigner(s.PrivateKey, s.HashAlgo)
	sig, err = signer.Sign(message)
	return
}

func GetSignableDataFromScript(
	g *gwtf.GoWithTheFlow,
	method string,
	args ...interface{},
) (signable []byte, err error) {
	filename := "../../../scripts/multisig/calc_signable_data.cdc"
	script := ParseCadenceTemplate(filename)

	cMethod, err := g.ScriptFromFile(filename, script).Argument(cadence.NewOptional(cadence.String(method))).RunReturns()
	signable = append(signable, ConvertCadenceByteArray(cMethod)...)

	// amount, err := cadence.NewUFix64(value)
	for _, arg := range args {
		var b cadence.Value
		switch arg.(type) {
		case string:
			// TODO: do not assume all args with string is for UFix64
			ufix64, err := cadence.NewUFix64(arg.(string))
			if err != nil {
				return nil, err
			}
			b, err = g.ScriptFromFile(filename, script).Argument(cadence.NewOptional(ufix64)).RunReturns()
			if err != nil {
				return nil, err
			}
		case uint64:
			b, err = g.ScriptFromFile(filename, script).Argument(cadence.NewOptional(cadence.UInt64(arg.(uint64)))).RunReturns()
			if err != nil {
				return nil, err
			}
		default:
			panic("arg type not supported")
		}
		signable = append(signable, ConvertCadenceByteArray(b)...)

	}
	return
}
