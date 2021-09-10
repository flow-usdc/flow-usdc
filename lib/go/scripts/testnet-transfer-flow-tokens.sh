#!/bin/bash

source .env

# using go scripts due to https://github.com/onflow/flow-cli/issues/373
# this issue is now fixed
cd lib/go/scripts
go run ./testnet-send-flow-tokens/send-flow-tokens.go allowance
go run ./testnet-send-flow-tokens/send-flow-tokens.go blocklister
go run ./testnet-send-flow-tokens/send-flow-tokens.go minter 
go run ./testnet-send-flow-tokens/send-flow-tokens.go minterController1 
go run ./testnet-send-flow-tokens/send-flow-tokens.go minterController2
go run ./testnet-send-flow-tokens/send-flow-tokens.go non-allowance
go run ./testnet-send-flow-tokens/send-flow-tokens.go non-blocklister
go run ./testnet-send-flow-tokens/send-flow-tokens.go non-minter
go run ./testnet-send-flow-tokens/send-flow-tokens.go non-multisig-account
go run ./testnet-send-flow-tokens/send-flow-tokens.go non-pauser
go run ./testnet-send-flow-tokens/send-flow-tokens.go non-vaulted-account
go run ./testnet-send-flow-tokens/send-flow-tokens.go pauser
go run ./testnet-send-flow-tokens/send-flow-tokens.go vaulted-account
go run ./testnet-send-flow-tokens/send-flow-tokens.go w-1000
go run ./testnet-send-flow-tokens/send-flow-tokens.go w-250-1
go run ./testnet-send-flow-tokens/send-flow-tokens.go w-250-2
go run ./testnet-send-flow-tokens/send-flow-tokens.go w-500-1
go run ./testnet-send-flow-tokens/send-flow-tokens.go w-500-2

