# export vars from root env file
ifneq (,$(wildcard ./.env))
	include .env
	export
endif

.PHONY: test

test:
	./lib/go/test.sh
