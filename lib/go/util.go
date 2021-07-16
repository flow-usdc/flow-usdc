package util

import (
	"bytes"
	"errors"
	"io/ioutil"
	"os"
	"time"

	"text/template"

	"github.com/bjartek/go-with-the-flow/gwtf"
	"github.com/onflow/cadence"
	"github.com/onflow/flow-go-sdk"
)

type Addresses struct {
	FungibleToken      string
	ExampleToken       string
	FiatTokenInterface string
	FiatToken          string
}

type TestEvent struct {
	Name   string
	Fields map[string]interface{}
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
	// addresses = Addresses{"ee82856bf20e2aa6", "01cf0e2f2f715450", "01cf0e2f2f715450", "01cf0e2f2f715450"}
	addresses = Addresses{os.Getenv("FUNGIBLE_TOKEN_ADDRESS"), os.Getenv("TOKEN_ACCOUNT_ADDRESS"), os.Getenv("TOKEN_ACCOUNT_ADDRESS"), os.Getenv("TOKEN_ACCOUNT_ADDRESS")}
	buf := &bytes.Buffer{}
	err = tmpl.Execute(buf, addresses)
	if err != nil {
		panic(err)
	}

	return buf.Bytes()
}

func ParseTestEvent(event flow.Event) *gwtf.FormatedEvent {
	return gwtf.ParseEvent(event, uint64(0), time.Now(), nil)
}

func NewExpectedEvent(name string) TestEvent {
	return TestEvent{
		Name:   "A." + addresses.FiatToken + ".FiatToken." + name,
		Fields: map[string]interface{}{},
	}
}

func (te TestEvent) AddField(fieldName string, fieldValue cadence.Value) TestEvent {
	te.Fields[fieldName] = gwtf.CadenceValueToInterface(fieldValue)
	return te
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
