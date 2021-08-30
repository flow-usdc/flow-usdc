#!/bin/bash

source .env

# Check to see if it's running in the right directory
if [ ! -f "./flow.json" ]; then
  echo "IMPORTANT: This script must be run from the 'flow-usdc' root folder, not a subdirectory"
  exit 1
fi

PROJECT_ROOT=$(pwd)
EXEC_PATH=/usr/local/bin/flow

shopt -s expand_aliases
alias flow='$EXEC_PATH -f $PROJECT_ROOT/flow.json'


echo "testnet-allowance:" 
echo $TESTNET_ALLOWANCE

cd lib/go
go run scripts/testnet/create_accounts.go allowance

# we create the first account and transfer flow tokens to it
# the first account is the USDC owner
# flow accounts create --network="$NETWORK" --key="$PK_TESTNET_ALLOWANCE" --signer=testnet-owner --key-weight=1000



# flow transactions send ./transactions/flowTokens/transfer_flow_tokens_testnet.cdc \
#   --arg=UFix64:10.0 \
#   --arg=Address:0x"$OWNER_ADDRESS" \
#   --signer="$SIGNER" \
#   --network="$NETWORK"
# 
