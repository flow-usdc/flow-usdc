# export vars from root env file
ifneq (,$(wildcard ./.env))
	include .env
	export
endif

.PHONY: test

test:
	./lib/go/test.sh

.PHONY: docs 

docs:
	go run lib/go/scripts/generate-docs/generate-transactions-md.go transactions > ./doc/TRANSACTIONS.md
	go run lib/go/scripts/generate-docs/generate-transactions-md.go scripts > ./doc/SCRIPTS.md

.PHONY: local-deploy

local-deploy:
	./.local.sh

.PHONY: testnet 

testnet:
	./testnet-create-accounts.sh
