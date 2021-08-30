package main

import (
	"log"

 	"github.com/bjartek/go-with-the-flow/v2/gwtf"
 	util "github.com/flow-usdc/flow-usdc"
	"os"
)

func main() {
	// This relative path to flow.json is  different in tests as it is the main package
 	jsonPath := "../../flow.json"
 	var flowJSON []string = []string{jsonPath}
    g := gwtf.NewGoWithTheFlow(flowJSON, os.Getenv("NETWORK"), false, 3)

    // name of the account
     account := os.Args[1]

    log.Println("---------")
    log.Println("")
    log.Println("")
    log.Println("account: ", account)

	txFilename := "../../transactions/flowTokens/create_account_testnet.cdc"
 	code := util.ParseCadenceTemplate(txFilename)


    pubkey:= g.Account(account).Key().ToConfig().PrivateKey.PublicKey().String()

	e, err := g.TransactionFromFile(txFilename, code).
		SignProposeAndPayAs("owner").
        StringArgument(pubkey[2:]).
		UFix64Argument("1000.0").
        RunE()
    if err != nil {
        log.Println(err)
    }

    log.Println(e)
    log.Println("")
    log.Println("")
    log.Println("---------")
	
}
