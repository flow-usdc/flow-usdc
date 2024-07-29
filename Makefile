.PHONY: test
test:
	flow-c1 test --cover --covercode="contracts" tests/*.cdc

.PHONY: ci
ci:
	flow-c1 test --cover --covercode="contracts" tests/*.cdc
