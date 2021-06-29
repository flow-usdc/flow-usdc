# export vars from root env file
ifneq (,$(wildcard ./.env))
	include .env
	export
endif

local:
	./lib/go/test.sh
