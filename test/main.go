package main

import (
	"bytes"
	"context"
	"io/ioutil"
	"os"
	"text/template"
	"time"

	"github.com/onflow/flow-go-sdk"
	"github.com/onflow/flow-go-sdk/client"
)

type Addresses struct {
	FungibleToken string
	ExampleToken  string
	USDCInterface string
	USDCToken string
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
