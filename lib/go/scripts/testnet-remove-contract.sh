#!/bin/bash

source .env

# using go scripts due to https://github.com/onflow/flow-cli/issues/373
# this issue is now fixed
cd lib/go/scripts
go run ./testnet-remove-contract/remove-contract.go


