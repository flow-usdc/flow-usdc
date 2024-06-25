# export vars from root env file
ifneq (,$(wildcard ./.env))
	include .env
	export
endif

.PHONY: test

test:
	./lib/go/test.sh
	flow-c1 test --cover --covercode="contracts" tests/*.cdc

.PHONY: docs 

docs:
	go run lib/go/scripts/generate-docs/generate-transactions-md.go transactions > ./doc/TRANSACTIONS.md
	go run lib/go/scripts/generate-docs/generate-transactions-md.go scripts > ./doc/SCRIPTS.md

.PHONY: local-deploy

local-deploy:
	./.local.sh

.PHONY: testnet-create-accounts

testnet-create-accounts:
	./lib/go/scripts/testnet-create-accounts.sh

.PHONY: testnet-transfer-flow-to-accounts

testnet-transfer-flow-tokens:
	./lib/go/scripts/testnet-transfer-flow-tokens.sh

testnet-remove-contract:
	./lib/go/scripts/testnet-remove-contract.sh