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

	txFilename := "../../../transactions/owner/remove_contract.cdc"
	code := util.ParseCadenceTemplate(txFilename)

	e, err := g.TransactionFromFile(txFilename, code).
		SignProposeAndPayAs("owner").
		StringArgument("FiatToken").
		RunE()
	if err != nil {
		log.Println(err)
	}

	log.Println(e)
	log.Println("")
	log.Println("")
	log.Println("---------")

}
