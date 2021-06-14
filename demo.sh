#!/bin/bash -x

# Import from env file
set -o allexport; source .env; set +o allexport

# Run the emulator with the config in ./flow.json
if [ "${NETWORK}" == "emulator" ]; then
  flow emulator &
  EMULATOR_PID=$!
  sleep 1
  SIGNER=emulator-account
  flow accounts create --network="$NETWORK" --key="$TOKEN_ACCOUNT_PK" --signer="$SIGNER"
else
  SIGNER=token-account
fi


NEW_VAULTED_ACCOUNT_SEED=$(hexdump -n 16 -e '4/4 "%08X" 1 "\n"' /dev/random)
NEW_VAULTED_ACCOUNT_SK=$(flow keys generate --seed="$NEW_VAULTED_ACCOUNT_SEED" -o inline --filter=Private)
NEW_VAULTED_ACCOUNT_PK=$(flow keys generate --seed="$NEW_VAULTED_ACCOUNT_SEED" -o inline --filter=Public)
NEW_VAULTED_ACCOUNT_ADDRESS=$(flow accounts create --network="$NETWORK" --key="$NEW_VAULTED_ACCOUNT_PK" --signer="$SIGNER" -o inline --filter=Address)

NON_VAULTED_ACCOUNT_SEED=$(hexdump -n 16 -e '4/4 "%08X" 1 "\n"' /dev/random)
NON_VAULTED_ACCOUNT_SK=$(flow keys generate --seed="$NON_VAULTED_ACCOUNT_SEED" -o inline --filter=Private)
NON_VAULTED_ACCOUNT_PK=$(flow keys generate --seed="$NON_VAULTED_ACCOUNT_SEED" -o inline --filter=Public)
NON_VAULTED_ACCOUNT_ADDRESS=$(flow accounts create --network="$NETWORK" --key="$NON_VAULTED_ACCOUNT_PK" --signer="$SIGNER" -o inline --filter=Address)

flow project deploy --network="$NETWORK" --update

export NEW_VAULTED_ACCOUNT_SK
export NEW_VAULTED_ACCOUNT_ADDRESS
export NON_VAULTED_ACCOUNT_SK
export NON_VAULTED_ACCOUNT_ADDRESS

go test ./... -cover -v

if [ "${NETWORK}" == "emulator" ]; then
  kill $EMULATOR_PID
fi
