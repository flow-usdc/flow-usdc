# export vars from root env file
ifneq (,$(wildcard ./.env))
	include .env
	export
endif

.PHONY: test

test:
	./lib/go/test.sh

doc/TRANSACTIONS.md:
	go run lib/go/scripts/generate-docs/generate-transactions-md.go > doc/TRANSACTIONS.md
