# export vars from root env file
ifneq (,$(wildcard ./.env))
	include .env
	export
endif

test:
	cd lib/go && ./test.sh
