package util

import (
	"bytes"
	"context"
	"errors"
	"io/ioutil"
	"os"
	"testing"
	"text/template"
	"time"

	"github.com/onflow/cadence"
	"github.com/onflow/flow-go-sdk"
	"github.com/onflow/flow-go-sdk/client"
	"github.com/stretchr/testify/assert"
	"google.golang.org/grpc"
)

type Addresses struct {
	FungibleToken string
	ExampleToken  string
	USDCInterface string
	USDCToken     string
}

func ParseCadenceTemplate(templatePath string) []byte {
	fb, err := ioutil.ReadFile(templatePath)
	if err != nil {
		panic(err)
	}

	tmpl, err := template.New("Template").Parse(string(fb))
	if err != nil {
		panic(err)
	}

	addresses := Addresses{os.Getenv("FUNGIBLE_TOKEN_ADDRESS"), os.Getenv("TOKEN_ACCOUNT_ADDRESS"), os.Getenv("TOKEN_ACCOUNT_ADDRESS"), os.Getenv("TOKEN_ACCOUNT_ADDRESS")}
	buf := &bytes.Buffer{}
	err = tmpl.Execute(buf, addresses)
	if err != nil {
		panic(err)
	}

	return buf.Bytes()
}

func ReadCadenceCode(ContractPath string) []byte {
	b, err := ioutil.ReadFile(ContractPath)
	if err != nil {
		panic(err)
	}
	return b
}

func WaitForSeal(ctx context.Context, c *client.Client, id flow.Identifier) (result *flow.TransactionResult, err error) {
	result, err = c.GetTransactionResult(ctx, id)
	if err != nil {
		return
	}

	if result.Error != nil {
		err = result.Error
		return
	}

	for result.Status != flow.TransactionStatusSealed {
		if result.Status == flow.TransactionStatusExpired {
			return result, errors.New("transaction expired")
		}

		time.Sleep(time.Second)
		result, err = c.GetTransactionResult(ctx, id)

		if err != nil {
			return
		}

		if result.Error != nil {
			err = result.Error
			return
		}
	}

	return result, nil
}

func SetupTestEnvironment(t *testing.T) (context.Context, *client.Client) {
	ctx := context.Background()
	flowClient, err := client.New(os.Getenv("RPC_ADDRESS"), grpc.WithInsecure())
	assert.NoError(t, err)

	return ctx, flowClient
}

func GetBalance(ctx context.Context, flowClient *client.Client, address string) (cadence.UFix64, error) {
	script := ParseCadenceTemplate("../../../scripts/get_balance.cdc")

	flowAddress := flow.HexToAddress(address)
	value, err := flowClient.ExecuteScriptAtLatestBlock(ctx, script, []cadence.Value{
		cadence.Address(flowAddress),
	})
	if err != nil {
		return 0, err
	}

	balance := value.(cadence.UFix64)
	return balance, nil
}
