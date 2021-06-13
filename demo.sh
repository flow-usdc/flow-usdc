#!/bin/bash -x

set -o allexport; source .env; set +o allexport

# Run the emulator with the config in ./flow.json
flow emulator --network=emulator &
EMULATOR_PID=$!

sleep 1

flow accounts create --key="$TOKEN_ACCOUNT_PK"

NEW_VAULTED_ACCOUNT_SEED=$(hexdump -n 16 -e '4/4 "%08X" 1 "\n"' /dev/random)
NEW_VAULTED_ACCOUNT_SK=$(flow keys generate --seed="$NEW_VAULTED_ACCOUNT_SEED" -o inline --filter=Private)
NEW_VAULTED_ACCOUNT_PK=$(flow keys generate --seed="$NEW_VAULTED_ACCOUNT_SEED" -o inline --filter=Public)
NEW_VAULTED_ACCOUNT_ADDRESS=$(flow accounts create --key="$NEW_VAULTED_ACCOUNT_PK" -o inline --filter=Address)

NON_VAULTED_ACCOUNT_SEED=$(hexdump -n 16 -e '4/4 "%08X" 1 "\n"' /dev/random)
NON_VAULTED_ACCOUNT_SK=$(flow keys generate --seed="$NON_VAULTED_ACCOUNT_SEED" -o inline --filter=Private)
NON_VAULTED_ACCOUNT_PK=$(flow keys generate --seed="$NON_VAULTED_ACCOUNT_SEED" -o inline --filter=Public)
NON_VAULTED_ACCOUNT_ADDRESS=$(flow accounts create --key="$NON_VAULTED_ACCOUNT_PK" -o inline --filter=Address)

flow project deploy --network=emulator

export NEW_VAULTED_ACCOUNT_SK
export NEW_VAULTED_ACCOUNT_ADDRESS
export NON_VAULTED_ACCOUNT_SK
export NON_VAULTED_ACCOUNT_ADDRESS

go test ./... -cover -v

kill $EMULATOR_PID
