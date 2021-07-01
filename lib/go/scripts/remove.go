package main

import (
	"context"
	"fmt"
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

	result, err := deploy.RemoveUSDCContract(ctx, flowClient, ownerAddress, skFT)
	if err != nil {
		panic(err)
	}

	fmt.Println(result.Events)
}
