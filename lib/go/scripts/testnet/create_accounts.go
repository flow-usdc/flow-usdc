package main

import (
	"log"

// 	"github.com/bjartek/go-with-the-flow/v2/gwtf"
// 	util "github.com/flow-usdc/flow-usdc"
	"os"
)

func main() {
	// This relative path to flow.json is  different in tests as it is the main package
// 	jsonPath := "../../flow.json"
// 	var flowJSON []string = []string{jsonPath}
    log.Println(os.Getenv("NETWORK"))
    log.Println(os.Getenv("FUNGIBLE_TOKEN_ADDRESS"))
	// _ = gwtf.NewGoWithTheFlow(flowJSON, os.Getenv("NETWORK"), false, 3)

    // name of the account
    // account := os.Args[1]

	// txFilename := "../../transactions/flowTokens/create_account_testnet.cdc"
// 	_= util.ParseCadenceTemplate(txFilename)


    // pubkey:= g.Account(account).Key().ToConfig().PrivateKey.PublicKey().String()
    // log.Println("pubkey", pubkey)

	// e, err := g.TransactionFromFile(txFilename, code).
	// 	SignProposeAndPayAs("owner").
    //     StringArgument(pubkey[2:]).
	// 	UFix64Argument("1000.0").
    //     RunE()
    // log.Println(err)
    // log.Println(e)
	
}
