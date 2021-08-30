package main

import (
	"log"

	"github.com/bjartek/go-with-the-flow/v2/gwtf"
	"github.com/flow-usdc/flow-usdc/deploy"
	"os"
)

func main() {
	// This relative path to flow.json is  different in tests as it is the main package
	jsonPath := "../../flow.json"
	var flowJSON []string = []string{jsonPath}
	g := gwtf.NewGoWithTheFlow(flowJSON, os.Getenv("NETWORK"), false, 3)

	_, err := deploy.DeployFiatTokenContract(g, "owner", "USDC", "0.1.0")
	if err != nil {
		log.Fatal("Cannot deploy contract")
	}
}
