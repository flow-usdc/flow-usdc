module github.com/flow-usdc/flow-usdc

go 1.16

replace github.com/bjartek/go-with-the-flow/v2 => github.com/flow-hydraulics/go-with-the-flow/v2 v2.0.0-20210828075816-542f0f58e499

// replace github.com/bjartek/go-with-the-flow/v2 => ../../../gwtf-usdc-fork

require (
	github.com/bjartek/go-with-the-flow/v2 v2.1.4
	github.com/onflow/cadence v0.18.1-0.20210621144040-64e6b6fb2337
	github.com/onflow/flow-go-sdk v0.20.1-0.20210623043139-533a95abf071
	github.com/stretchr/testify v1.7.0
)
