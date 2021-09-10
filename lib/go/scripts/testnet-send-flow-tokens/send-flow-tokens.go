package main

import (
	"log"

	"os"

	"github.com/bjartek/go-with-the-flow/v2/gwtf"
	util "github.com/flow-usdc/flow-usdc"
)

func main() {
	// This relative path to flow.json is  different in tests as it is the main package
	jsonPath := "../../../flow.json"
	var flowJSON []string = []string{jsonPath}
	g := gwtf.NewGoWithTheFlow(flowJSON, os.Getenv("NETWORK"), false, 3)

	// name of the account
	account := os.Args[1]

	log.Println("---------")
	log.Println("")
	log.Println("")
	log.Println("account: ", account)

	txFilename := "../../../transactions/flowTokens/transfer_flow_tokens_testnet.cdc"
	code := util.ParseCadenceTemplate(txFilename)

	e, err := g.TransactionFromFile(txFilename, code).
		SignProposeAndPayAs("owner").
		UFix64Argument("20.0").
		AccountArgument(account).
		RunE()
	if err != nil {
		log.Println(err)
	}

	log.Println(e)
	log.Println("")
	log.Println("")
	log.Println("---------")

}
