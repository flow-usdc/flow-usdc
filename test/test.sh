#!/bin/bash -x

OS_NAME=$(uname -s | awk '{print tolower($0)}')
CPU_ARCH=$(uname -m)
EXEC_PATH=../.github/flow-"$OS_NAME"-"$CPU_ARCH"

shopt -s expand_aliases
alias flow='$EXEC_PATH'

# Import from env file
set -o allexport; source .env; set +o allexport

# Run the emulator with the config in ./flow.json
if [ "${NETWORK}" == "emulator" ]; then
  # setting block-time of 1s to emulate testnet + mainnet tempo
  flow emulator -b 1s &
  EMULATOR_PID=$!
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

NEW_VAULTED_ACCOUNT_SEED=$(hexdump -n 16 -e '4/4 "%08X" 1 "\n"' /dev/random)
NEW_VAULTED_ACCOUNT_SK=$(flow keys generate --seed="$NEW_VAULTED_ACCOUNT_SEED" -o inline --filter=Private)
NEW_VAULTED_ACCOUNT_PK=$(flow keys generate --seed="$NEW_VAULTED_ACCOUNT_SEED" -o inline --filter=Public)
NEW_VAULTED_ACCOUNT_ADDRESS=$(flow accounts create --network="$NETWORK" --key="$NEW_VAULTED_ACCOUNT_PK" --signer="$SIGNER" -o inline --filter=Address)

if [ "${NETWORK}" == "testnet" ]; then
  flow transactions send ../transactions/transfer_flow_tokens_testnet.cdc \
    --arg=UFix64:0.001 \
    --arg=Address:0x"$NEW_VAULTED_ACCOUNT_ADDRESS" \
    --signer=token-account \
    --network=testnet
fi

NON_VAULTED_ACCOUNT_SEED=$(hexdump -n 16 -e '4/4 "%08X" 1 "\n"' /dev/random)
NON_VAULTED_ACCOUNT_SK=$(flow keys generate --seed="$NON_VAULTED_ACCOUNT_SEED" -o inline --filter=Private)
NON_VAULTED_ACCOUNT_PK=$(flow keys generate --seed="$NON_VAULTED_ACCOUNT_SEED" -o inline --filter=Public)
NON_VAULTED_ACCOUNT_ADDRESS=$(flow accounts create --network="$NETWORK" --key="$NON_VAULTED_ACCOUNT_PK" --signer="$SIGNER" -o inline --filter=Address)

flow project deploy --network="$NETWORK" --update

export NEW_VAULTED_ACCOUNT_SK
export NEW_VAULTED_ACCOUNT_ADDRESS
export NON_VAULTED_ACCOUNT_SK
export NON_VAULTED_ACCOUNT_ADDRESS

TEST_RESULT=0

if go test ./deploy -cover -v; then true; else TEST_RESULT=1; fi
if go test ./exampleToken -cover -v; then true; else TEST_RESULT=1; fi

if [ "${NETWORK}" == "emulator" ]; then
  kill $EMULATOR_PID
fi

exit $TEST_RESULT
