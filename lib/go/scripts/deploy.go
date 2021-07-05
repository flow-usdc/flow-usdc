package main

import (
	"github.com/bjartek/go-with-the-flow/gwtf"
	"github.com/flow-usdc/flow-usdc/deploy"
)

func main() {
	// This relative path to flow.json is  different in tests as it is the main package
	g := gwtf.NewGoWithTheFlow("../../flow.json")

	deploy.DeployUSDCContract(g, "owner")
}
