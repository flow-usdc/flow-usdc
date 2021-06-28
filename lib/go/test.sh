#!/bin/bash

set -o allexport; source .env; set +o allexport
set +ex

OS_NAME=$(uname -s | awk '{print tolower($0)}')
CPU_ARCH=$(uname -m)
EXEC_PATH=../.github/flow-"$OS_NAME"-"$CPU_ARCH"

shopt -s expand_aliases
alias flow='$EXEC_PATH'

# Import from env file

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
  flow accounts create --network="$NETWORK" --key="$TOKEN_ACCOUNT_PK" --signer="$SIGNER"
  # update this file to use env address
  flow transactions send ../transactions/transfer_flow_tokens_emulator.cdc \
    --arg=UFix64:100.0 \
    --arg=Address:0x"$TOKEN_ACCOUNT_ADDRESS" \
    --signer="$SIGNER" \
    --network="$NETWORK"
else
  SIGNER=token-account
fi


flow project deploy --network="$NETWORK" --update
go run scripts/deploy.go
go test ./deploy -v

PAUSER_SEED=$(hexdump -n 16 -e '4/4 "%08X" 1 "\n"' /dev/random)
PAUSER_SK=$(flow keys generate --seed="$PAUSER_SEED" -o inline --filter=Private)
PAUSER_PK=$(flow keys generate --seed="$PAUSER_SEED" -o inline --filter=Public)
PAUSER_ADDRESS=$(flow accounts create --network="$NETWORK" --key="$PAUSER_PK" --signer="$SIGNER" -o inline --filter=Address)

export PAUSER_ADDRESS
export PAUSER_SK
go test ./pause -v

NEW_VAULTED_ACCOUNT_SEED=$(hexdump -n 16 -e '4/4 "%08X" 1 "\n"' /dev/random)
NEW_VAULTED_ACCOUNT_SK=$(flow keys generate --seed="$NEW_VAULTED_ACCOUNT_SEED" -o inline --filter=Private)
NEW_VAULTED_ACCOUNT_PK=$(flow keys generate --seed="$NEW_VAULTED_ACCOUNT_SEED" -o inline --filter=Public)
NEW_VAULTED_ACCOUNT_ADDRESS=$(flow accounts create --network="$NETWORK" --key="$NEW_VAULTED_ACCOUNT_PK" --signer="$SIGNER" -o inline --filter=Address)

if [ "${NETWORK}" == "testnet" ]; then
  flow transactions send ../../transactions/transfer_flow_tokens_testnet.cdc \
    -f "$FLOW_CONFIG_PATH" \
    --arg=UFix64:0.001 \
    --arg=Address:0x"$NEW_VAULTED_ACCOUNT_ADDRESS" \
    --signer=token-account \
    --network=testnet
fi

NON_VAULTED_ACCOUNT_SEED=$(hexdump -n 16 -e '4/4 "%08X" 1 "\n"' /dev/random)
NON_VAULTED_ACCOUNT_SK=$(flow keys generate --seed="$NON_VAULTED_ACCOUNT_SEED" -o inline --filter=Private)
NON_VAULTED_ACCOUNT_PK=$(flow keys generate --seed="$NON_VAULTED_ACCOUNT_SEED" -o inline --filter=Public)
NON_VAULTED_ACCOUNT_ADDRESS=$(flow accounts create --network="$NETWORK" --key="$NON_VAULTED_ACCOUNT_PK" --signer="$SIGNER" -o inline --filter=Address)
export NEW_VAULTED_ACCOUNT_SK
export NEW_VAULTED_ACCOUNT_ADDRESS
export NON_VAULTED_ACCOUNT_SK
export NON_VAULTED_ACCOUNT_ADDRESS

go test ./vault  -v