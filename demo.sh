#!/bin/bash -x

# Run the emulator with the config in ./flow.json
flow emulator -f flow.json -f flow.emulator.json --network=emulator &
EMULATOR_PID=$!

sleep 1

flow accounts create \
  --key=9e5b55b79e663debe5742c3e1ba53aeb71346c338e89616aa6b8715ab0b6fb92c7a1d7811dd31ae7959687677c2f2918098543b5b1de5fa8725547580ca9dbdd \
  -f flow.json -f flow.emulator.json

flow accounts create \
  --key=440a5d7d3dd3c71334d8610565f958e4ce98432f543a445f300d4d3382e597e3507d7bf65ca412cb14c1d16cd2995df229cb882d1aab7721126120fa0c60a56a \
  -f flow.json -f flow.emulator.json

flow accounts create \
  --key=9b3b29cb2013807902f376cc85d67206236af09662587bbd92ccfd3b186a2520bce78fd6d16a09d4a87ca0fdac1daa0d1dc5af1ebdec4cbc9252cf24822a9409 \
  -f flow.json -f flow.emulator.json

flow project deploy \
  -f flow.json -f flow.emulator.json \
  --network=emulator \

RPC_ADDRESS=localhost:3569 go test ./... -cover -v

kill $EMULATOR_PID
