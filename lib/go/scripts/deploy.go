package main

import (
	"log"

	"github.com/bjartek/go-with-the-flow/gwtf"
	"github.com/flow-usdc/flow-usdc/deploy"
)

func main() {
	// This relative path to flow.json is  different in tests as it is the main package
	g := gwtf.NewGoWithTheFlow("../../flow.json")

	err := deploy.DeployUSDCContract(g, "owner")
	if err != nil {
		log.Fatal("Cannot deploy contract")
	}
}
