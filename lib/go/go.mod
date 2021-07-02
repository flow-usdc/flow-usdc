module github.com/flow-usdc/flow-usdc

go 1.16

replace github.com/bjartek/go-with-the-flow => ./gwtf

require (
	github.com/bjartek/go-with-the-flow v1.18.1
	github.com/golang/protobuf v1.5.2 // indirect
	github.com/onflow/cadence v0.18.0
	github.com/onflow/flow-go-sdk v0.20.0
	github.com/onflow/flow/protobuf/go/flow v0.2.0 // indirect
	github.com/stretchr/testify v1.7.0
	google.golang.org/grpc v1.38.0
)
