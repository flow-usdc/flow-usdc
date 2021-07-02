package main

import (
	"context"
	"os"

	"github.com/flow-usdc/flow-usdc/deploy"
	"github.com/onflow/flow-go-sdk/client"
	"google.golang.org/grpc"
)

func main() {
	ctx := context.Background()
	flowClient, err := client.New(os.Getenv("RPC_ADDRESS"), grpc.WithInsecure())
	if err != nil {
		panic(err)
	}

	ownerAddress := os.Getenv("TOKEN_ACCOUNT_ADDRESS")
	skFT := os.Getenv("TOKEN_ACCOUNT_KEYS")

	deploy.DeployUSDCContract(ctx, flowClient, ownerAddress, skFT)
}
