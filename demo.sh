#!/bin/bash

# Run the emulator with the config in ./flow.json, which
# includes ./flow.emulator.json as well
flow emulator &
EMULATOR_PID=$!

make test

# Account A, the one that creates the contract itself
# PK_A=$(flow keys generate --seed=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx --filter=Public)
# ACCOUNT_A=$(flow accounts create --key="$PK_A" --signer=emulator-account -o inline --filter=Address)

# Account B, which has the Vault enabled to receive our token
# PK_B=$(flow keys generate --seed=yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy --filter=Public)
# ACCOUNT_B=$(flow accounts create --key="$PK_B" --signer=emulator-account -o inline --filter=Address)

# Account C, which does not have the Vault enabled
# PK_C=$(flow keys generate --seed=zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz --filter=Public)
# ACCOUNT_C=$(flow accounts create --key="$PK_C" --signer=emulator-account -o inline --filter=Address)


# flow accounts add-contract ExampleToken ./contracts/ExampleToken.cdc --signer=ft-account
#
# flow scripts execute ./contracts/scripts/get_supply.cdc

# Minting Account gets a Vault for free
# flow scripts execute ./contracts/scripts/get_balance.cdc --arg Address:0x"$ACCOUNT_A"

# Set up a Vault for Account B
# flow transactions send ./transactions/setup_account.cdc --signer=receiver-account
# flow scripts execute ./contracts/scripts/get_balance.cdc --arg Address:0x"$ACCOUNT_B"

# Non-Vaulted Account, should panic + revert
# flow scripts execute ./contracts/scripts/get_balance.cdc --arg Address:0x"$ACCOUNT_C"

# Transfer from Account A to Account B
# flow transactions send ./transactions/transfer_tokens.cdc \
#   --arg UFix64:500.0 \
#   --arg Address:0x"$ACCOUNT_B" \
#   --signer=ft-account

# flow scripts execute ./contracts/scripts/get_balance.cdc --arg Address:0x"$ACCOUNT_B"

# Transfer from Account B back to Account A
# flow transactions send ./transactions/transfer_tokens.cdc \
#   --arg UFix64:50.0 \
#   --arg Address:0x"$ACCOUNT_A" \
#   --signer=receiver-account

# flow scripts execute ./contracts/scripts/get_balance.cdc --arg Address:0x"$ACCOUNT_A"

# Transfer from Account A to Account C, should panic + revert
# flow transactions send ./transactions/transfer_tokens.cdc \
#   --arg UFix64:50.0 \
#   --arg Address:0x"$ACCOUNT_C" \
#   --signer=ft-account

# Prints Money
# flow transactions send ./transactions/mint_tokens.cdc \
#   --arg Address:0x"$ACCOUNT_A" \
#   --arg UFix64:5000.0 \
#   --signer=ft-account

# flow scripts execute ./contracts/scripts/get_balance.cdc --arg Address:0x"$ACCOUNT_A"

# Burns Money
# flow transactions send ./transactions/burn_tokens.cdc \
#   --arg UFix64:2000.0 \
#   --signer=ft-account

# flow scripts execute ./contracts/scripts/get_balance.cdc --arg Address:0x"$ACCOUNT_A"

# Finally, let's make ACCOUNT_B an admin and test minting and burning with them
# flow transactions build ./transactions/create_admin.cdc \
#   --authorizer ft-account \
#   --authorizer receiver-account \
#   --proposer ft-account \
#   --payer receiver-account \
#   --filter payload \
#   --save transaction.rlp

# Payload Signature
# flow transactions sign ./transaction.rlp \
#   --signer ft-account \
#   --filter payload \
#   --save signed.rlp

# Envelope Signature
# flow transactions sign ./signed.rlp \
#   --signer receiver-account \
#   --filter payload \
#   --save signed.rlp

# flow transactions send-signed ./signed.rlp

# flow transactions send ./transactions/mint_tokens.cdc \
#   --arg Address:0x"$ACCOUNT_B" \
#   --arg UFix64:5000.0 \
#   --signer=receiver-account
# 
# flow scripts execute ./contracts/scripts/get_balance.cdc --arg Address:0x"$ACCOUNT_B"
# 
# flow transactions send ./transactions/burn_tokens.cdc \
#   --arg UFix64:4000.0 \
#   --signer=receiver-account
# 
# flow scripts execute ./contracts/scripts/get_balance.cdc --arg Address:0x"$ACCOUNT_B"

# Clean up, kill the emulator and exit
# rm -f signed.rlp
# rm -f transaction.rlp
kill $EMULATOR_PID

