package util

import (
	"bytes"
	"encoding/hex"
	"errors"
	"io/ioutil"
	"os"
	"testing"
	"time"

	"text/template"

	"github.com/bjartek/go-with-the-flow/v2/gwtf"
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
const Config = "../../../flow.json"

var FlowJSON []string = []string{Config}

type Addresses struct {
	FungibleToken      string
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
	// addresses = Addresses{"ee82856bf20e2aa6", "01cf0e2f2f715450", "01cf0e2f2f715450", "01cf0e2f2f715450", "01cf0e2f2f715450"}
	addresses = Addresses{os.Getenv("FUNGIBLE_TOKEN_ADDRESS"), os.Getenv("OWNER_ADDRESS"), os.Getenv("OWNER_ADDRESS"), os.Getenv("OWNER_ADDRESS")}

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

func NewExpectedEvent(contract string, name string) TestEvent {
	return TestEvent{
		Name:   "A." + addresses.FiatToken + "." + contract + "." + name,
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

// Gets the address in the format of a hex string from an account name
func GetAccountAddr(g *gwtf.GoWithTheFlow, name string) string {
	address := g.Account(name).Address().String()
	zeroPrefix := "0"
	if string(address[0]) == zeroPrefix {
		address = address[1:]
	}
	return "0x" + address
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

func GetName(g *gwtf.GoWithTheFlow) (result string, err error) {
	filename := "../../../scripts/contract/get_name.cdc"
	script := ParseCadenceTemplate(filename)
	r, err := g.ScriptFromFile(filename, script).RunReturns()
	result = r.ToGoValue().(string)
	return
}

func GetVersion(g *gwtf.GoWithTheFlow) (result string, err error) {
	filename := "../../../scripts/contract/get_version.cdc"
	script := ParseCadenceTemplate(filename)
	r, err := g.ScriptFromFile(filename, script).RunReturns()
	result = r.ToGoValue().(string)
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

func GetUUID(g *gwtf.GoWithTheFlow, account string, resourceName string) (r uint64, err error) {
	filename := "../../../scripts/contract/get_resource_uuid.cdc"
	script := ParseCadenceTemplate(filename)
	value, err := g.ScriptFromFile(filename, script).AccountArgument(account).StringArgument(resourceName).RunReturns()
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

// Multisig utility functions and type

// Arguement for Multisig functions `Multisig_SignAndSubmit`
// This allows for generic functions to type cast the arguments into
// correct cadence types.
// i.e. for a cadence.UFix64, Arg {V: "12.00", T: "UFix64"}
type Arg struct {
	V interface{}
	T string
}

// Signing payload offline
func SignPayloadOffline(g *gwtf.GoWithTheFlow, message []byte, signingAcct string) (sig string, err error) {
	s := g.Account(signingAcct).Key().ToConfig()
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

func ConvertToCadenceValue(g *gwtf.GoWithTheFlow, args ...Arg) (a []cadence.Value, err error) {
	for _, arg := range args {
		var b cadence.Value
		switch arg.T {
		case "String":
			b = cadence.String(arg.V.(string))
		case "UFix64":
			b, err = cadence.NewUFix64(arg.V.(string))
		case "UInt8":
			b = cadence.NewUInt8(arg.V.(uint8))
		case "UInt64":
			b = cadence.UInt64(arg.V.(uint64))
		case "Address":
			b = cadence.BytesToAddress(g.Account(arg.V.(string)).Address().Bytes())
		default:
			err = errors.New("Type not supported")
		}
		a = append(a, b)
	}
	return
}

func MultiSig_Sign(
	g *gwtf.GoWithTheFlow,
	txIndex uint64,
	signerAcct string,
	resourceAcct string,
	resourceName string,
	method string,
	args ...Arg,
) (sig string, err error) {

	cadenceArgs, err := ConvertToCadenceValue(g, args...)
	if err != nil {
		return
	}

	signable, err := GetSignableDataFromScript(g, txIndex, method, cadenceArgs...)
	if err != nil {
		return
	}

	sig, err = SignPayloadOffline(g, signable, signerAcct)
	return
}

func MultiSig_SignAndSubmit(
	g *gwtf.GoWithTheFlow,
	newPayload bool,
	txIndex uint64,
	signerAcct string,
	resourceAcct string,
	resourceName string,
	method string,
	args ...Arg,
) (events []*gwtf.FormatedEvent, err error) {

	cadenceArgs, err := ConvertToCadenceValue(g, args...)
	if err != nil {
		return nil, err
	}

	signable, err := GetSignableDataFromScript(g, txIndex, method, cadenceArgs...)
	if err != nil {
		return
	}

	sig, err := SignPayloadOffline(g, signable, signerAcct)
	if err != nil {
		return
	}
	if newPayload {
		return multiSig_NewPayload(g, sig, txIndex, method, cadenceArgs, signerAcct, resourceAcct, resourceName)
	} else {
		return multiSig_AddPayloadSignature(g, sig, txIndex, signerAcct, resourceAcct, resourceName)
	}
}

func multiSig_NewPayload(
	g *gwtf.GoWithTheFlow,
	sig string,
	txIndex uint64,
	method string,
	args []cadence.Value,
	signerAcct string,
	resourceAcct string,
	resourceName string,
) (events []*gwtf.FormatedEvent, err error) {
	txFilename := "../../../transactions/onChainMultiSig/add_new_payload.cdc"
	txScript := ParseCadenceTemplate(txFilename)

	path, err := GetPubSignerPath(g, resourceAcct, resourceName)
	if err != nil {
		return
	}
	signerPubKey := g.Account(signerAcct).Key().ToConfig().PrivateKey.PublicKey().String()
	e, err := g.TransactionFromFile(txFilename, txScript).
		SignProposeAndPayAs(signerAcct).
		StringArgument(sig).
		UInt64Argument(txIndex).
		StringArgument(method).
		Argument(cadence.NewArray(args)).
		StringArgument(signerPubKey[2:]).
		AccountArgument(resourceAcct).
		Argument(path).
		RunE()
	events = ParseTestEvents(e)
	return
}

func MultiSig_SignAndSubmitNewPayload(
	g *gwtf.GoWithTheFlow,
	txIndex uint64,
	signerAcct string,
	resourceAcct string,
	resourceName string,
	method string,
	args ...Arg,
) (events []*gwtf.FormatedEvent, err error) {

	cadenceArgs, err := ConvertToCadenceValue(g, args...)
	if err != nil {
		return nil, err
	}

	signable, err := GetSignableDataFromScript(g, txIndex, method, cadenceArgs...)
	if err != nil {
		return
	}

	sig, err := SignPayloadOffline(g, signable, signerAcct)
	if err != nil {
		return
	}

	txFilename := "../../../transactions/onChainMultiSig/add_new_payload.cdc"
	txScript := ParseCadenceTemplate(txFilename)

	path, err := GetPubSignerPath(g, resourceAcct, resourceName)
	if err != nil {
		return
	}
	signerPubKey := g.Account(signerAcct).Key().ToConfig().PrivateKey.PublicKey().String()
	e, err := g.TransactionFromFile(txFilename, txScript).
		SignProposeAndPayAs(signerAcct).
		StringArgument(sig).
		UInt64Argument(txIndex).
		StringArgument(method).
		Argument(cadence.NewArray(cadenceArgs)).
		StringArgument(signerPubKey[2:]).
		AccountArgument(resourceAcct).
		Argument(path).
		RunE()
	events = ParseTestEvents(e)
	return
}
func multiSig_AddPayloadSignature(
	g *gwtf.GoWithTheFlow,
	sig string,
	txIndex uint64,
	signerAcct string,
	resourceAcct string,
	resourceName string,
) (events []*gwtf.FormatedEvent, err error) {
	txFilename := "../../../transactions/onChainMultiSig/add_payload_signature.cdc"
	txScript := ParseCadenceTemplate(txFilename)

	path, err := GetPubSignerPath(g, resourceAcct, resourceName)
	if err != nil {
		return
	}
	signerPubKey := g.Account(signerAcct).Key().ToConfig().PrivateKey.PublicKey().String()
	e, err := g.TransactionFromFile(txFilename, txScript).
		SignProposeAndPayAs(signerAcct).
		StringArgument(sig).
		UInt64Argument(txIndex).
		StringArgument(signerPubKey[2:]).
		AccountArgument(resourceAcct).
		Argument(path).
		RunE()
	events = ParseTestEvents(e)
	return
}

func MultiSig_ExecuteTx(
	g *gwtf.GoWithTheFlow,
	index uint64,
	payerAcct string,
	resourceAcct string,
	resourceName string,
) (events []*gwtf.FormatedEvent, err error) {
	txFilename := "../../../transactions/onChainMultiSig/executeTx.cdc"
	txScript := ParseCadenceTemplate(txFilename)

	path, err := GetPubSignerPath(g, resourceAcct, resourceName)
	if err != nil {
		return
	}

	e, err := g.TransactionFromFile(txFilename, txScript).
		SignProposeAndPayAs(payerAcct).
		UInt64Argument(index).
		AccountArgument(resourceAcct).
		Argument(path).
		RunE()
	events = ParseTestEvents(e)
	return
}

func MultiSig_SubmitMultiAndExecute(
	g *gwtf.GoWithTheFlow,
	sigs []string,
	txIndex uint64,
	signerAccts []string,
	resourceAcct string,
	resourceName string,
	payerAcct string,
	method string,
	args ...Arg,
) (events []*gwtf.FormatedEvent, err error) {
	txFilename := "../../../transactions/onChainMultiSig/add_and_execute.cdc"
	txScript := ParseCadenceTemplate(txFilename)

	cadenceArgs, err := ConvertToCadenceValue(g, args...)
	if err != nil {
		return nil, err
	}

	path, err := GetPubSignerPath(g, resourceAcct, resourceName)
	if err != nil {
		return
	}

	var signerPubKeys []cadence.Value
	var signatures []cadence.Value
	var pk string

	for i := 0; i < len(sigs); i++ {
		pk = g.Account(signerAccts[i]).Key().ToConfig().PrivateKey.PublicKey().String()
		signerPubKeys = append(signerPubKeys, cadence.NewString(pk[2:]))
		signatures = append(signatures, cadence.NewString(sigs[i]))
	}

	sigs_array := cadence.NewArray(signatures)
	pubkey_array := cadence.NewArray(signerPubKeys)
	e, err := g.TransactionFromFile(txFilename, txScript).
		SignProposeAndPayAs(payerAcct).
		Argument(sigs_array).
		UInt64Argument(txIndex).
		StringArgument(method).
		Argument(cadence.NewArray(cadenceArgs)).
		Argument(pubkey_array).
		AccountArgument(resourceAcct).
		Argument(path).
		RunE()
	events = ParseTestEvents(e)
	return
}

func GetStoreKeys(g *gwtf.GoWithTheFlow, resourceAcct string, resourceName string) (result []string, err error) {
	filename := "../../../scripts/onChainMultiSig/get_store_keys.cdc"
	script := ParseCadenceTemplate(filename)
	path, err := GetPubSignerPath(g, resourceAcct, resourceName)
	if err != nil {
		return
	}
	value, err := g.ScriptFromFile(filename, script).AccountArgument(resourceAcct).Argument(path).RunReturns()
	if err != nil {
		return
	}
	result = ConvertCadenceStringArray(value)
	return
}

func GetKeyWeight(g *gwtf.GoWithTheFlow, signerAcct string, resourceAcct string, resourceName string) (result cadence.UFix64, err error) {
	filename := "../../../scripts/onChainMultiSig/get_key_weight.cdc"
	script := ParseCadenceTemplate(filename)
	signerPubKey := g.Account(signerAcct).Key().ToConfig().PrivateKey.PublicKey().String()[2:]
	path, err := GetPubSignerPath(g, resourceAcct, resourceName)
	if err != nil {
		return
	}
	value, err := g.ScriptFromFile(filename, script).
		AccountArgument(resourceAcct).
		StringArgument(signerPubKey).
		Argument(path).
		RunReturns()
	if err != nil {
		return
	}
	result = value.(cadence.UFix64)
	return
}

func GetTxIndex(g *gwtf.GoWithTheFlow, resourceAcct string, resourceName string) (result uint64, err error) {
	filename := "../../../scripts/onChainMultiSig/get_tx_index.cdc"
	script := ParseCadenceTemplate(filename)
	path, err := GetPubSignerPath(g, resourceAcct, resourceName)
	if err != nil {
		return
	}
	value, err := g.ScriptFromFile(filename, script).AccountArgument(resourceAcct).Argument(path).RunReturns()
	if err != nil {
		return
	}
	result = value.ToGoValue().(uint64)
	return
}

func GetPubSignerPath(g *gwtf.GoWithTheFlow, resourceAcct string, resourceName string) (result cadence.Value, err error) {
	filename := "../../../scripts/onChainMultiSig/get_pubsigner_path.cdc"
	script := ParseCadenceTemplate(filename)
	result, err = g.ScriptFromFile(filename, script).StringArgument(resourceName).RunReturns()
	return
}

func ContainsKey(g *gwtf.GoWithTheFlow, resourceAcct string, resourceName string, key string) (result bool, err error) {
	keys, err := GetStoreKeys(g, resourceAcct, resourceName)
	result = false
	for _, k := range keys {
		if k == key {
			result = true
			return
		}
	}
	return
}

func GetMultiSigKeys(g *gwtf.GoWithTheFlow) (MultiSigPubKeys []cadence.Value, MultiSigKeyWeights []cadence.Value, MultiSigAlgos []cadence.Value) {
	pk1000 := g.Account(Acct1000).Key().ToConfig().PrivateKey.PublicKey().String()
	pk500_1 := g.Account(Acct500_1).Key().ToConfig().PrivateKey.PublicKey().String()
	pk500_2 := g.Account(Acct500_2).Key().ToConfig().PrivateKey.PublicKey().String()
	pk250_1 := g.Account(Acct250_1).Key().ToConfig().PrivateKey.PublicKey().String()
	pk250_2 := g.Account(Acct250_2).Key().ToConfig().PrivateKey.PublicKey().String()

	w1000, _ := cadence.NewUFix64("1000.0")
	w500, _ := cadence.NewUFix64("500.0")
	w250, _ := cadence.NewUFix64("250.0")

	MultiSigPubKeys = []cadence.Value{
		cadence.String(pk1000[2:]),
		cadence.String(pk500_1[2:]),
		cadence.String(pk500_2[2:]),
		cadence.String(pk250_1[2:]),
		cadence.String(pk250_2[2:]),
	}

	MultiSigAlgos = []cadence.Value{
		cadence.NewUInt8(1),
		cadence.NewUInt8(1),
		cadence.NewUInt8(1),
		cadence.NewUInt8(1),
		cadence.NewUInt8(1),
	}
	MultiSigKeyWeights = []cadence.Value{w1000, w500, w500, w250, w250}
	return
}
