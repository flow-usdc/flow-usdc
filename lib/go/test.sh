#!/bin/bash

# Check to see if it's running in the right directory
if [ ! -f "./flow.json" ]; then
  echo "IMPORTANT: This script must be run from the 'flow-usdc' root folder, not a subdirectory"
  exit 1
fi

# errexit + xtrace
set -ex

OS_NAME=$(uname -s | awk '{print tolower($0)}')
CPU_ARCH=$(uname -m)
PROJECT_ROOT=$(pwd)
EXEC_PATH="$PROJECT_ROOT"/.github/flow-"$OS_NAME"-"$CPU_ARCH"

shopt -s expand_aliases
alias flow='$EXEC_PATH -f $PROJECT_ROOT/flow.json'

# Run the emulator with the config in ./flow.json
if [ "${NETWORK}" == "emulator" ]; then
  # setting block-time of 1s to emulate testnet + mainnet tempo
  flow emulator -b 1s &
  EMULATOR_PID=$!

  function tearDown {
    kill $EMULATOR_PID
  }

  trap tearDown EXIT
  sleep 1
  SIGNER=emulator-account
  # we create the first account and transfer flow tokens to it
  # the first account is the FiatToken owner
  OWNER_PK=46acb0e0918e09a50fc2a6b12f14fc00822ad7dac6c6fd92427ec675b9745cbe5ae93d790e6fdd0683d7dd17b6156cc4201def8d6a992807796a5ce4a789005f

  flow version
  flow accounts create --network="$NETWORK" --key="$OWNER_PK" --signer="$SIGNER"
  flow transactions send ./transactions/flowTokens/transfer_flow_tokens_emulator.cdc \
    100.0 0x01cf0e2f2f715450 --signer="$SIGNER"  --network="$NETWORK"
fi

flow project deploy --network="$NETWORK" --update=true


# NOW we switch to the go folder, where commands _can_ be run in place.
cd lib/go
go clean -testcache

# TODO: fix & run the remaining tests
go run scripts/deploy/deploy.go
go test ./deploy -run FiatToken -v
go test ./vault -v
#go test ./pause -v
#go test ./blocklist -v
#go test ./mint -run Controller -v
#go test ./deploy -run Upgrade -v
#go test ./mint -run MintBurn -v
#go test ./mint -run MasterMinterMultiSig -v
