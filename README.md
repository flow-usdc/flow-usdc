# The CENTRE Fiat Token, on Flow _(flow-usdc)_

> An implementation of the CENTRE Fiat Token in Cadence, on the Flow Blockchain.

<!-- markdownlint-configure-file { "MD013": { "line_length": 100 } } -->

[![standard-readme compliant](https://img.shields.io/badge/readme%20style-standard-lightgreen.svg?style=flat-square)](https://github.com/RichardLitt/standard-readme)
[![Tests](https://github.com/flow-usdc/flow-usdc/actions/workflows/tests-main.yml/badge.svg)](https://github.com/flow-usdc/flow-usdc/actions/workflows/tests-main.yml)
[![Static Analysis](https://github.com/flow-usdc/flow-usdc/actions/workflows/static-analysis.yml/badge.svg)](https://github.com/flow-usdc/flow-usdc/actions/workflows/static-analysis.yml)

<!-- TODO: Banner? -->

A [`FiatToken`] on the Flow blockchain, written in Cadence, which implements interfaces defined
in the following contracts:

* **[`FungibleToken`] (a.k.a. ERC20)**, which provides the baseline Vault (a.k.a Ownable) resource
and interfaces for compatibility.
* **[`FiatTokenInterface`]**, implemented in this codebase. This interface builds off of the above
`FungibleToken` core contract, adding the following resource interfaces, as well as the related
states and events
  * **Delegated Minting: MasterMinter, MinterControllers and Minters**:
  `MasterMinter` can set states in `managedMinter` to  delegate
  `MinterControllers` to control the allowance / removal of a `Minter`.
  Both `MinterController` and `Minter` resources are created by the users
  and the unique resource uuid is stored in the `managedMinter` and `minterAllowances` states.
  Please see [delegation process] for details.
  * **Pausing and Unpausing: PauseExecutor and Pauser**: If a situation like a major bug discovery
  or a serious key compromise,
  a `Pauser` will be able to halt all transfers and approvals contract-wide,
  until a mitigation takes place.
  `Pauser` is granted the capability to pause / unpause a contract by the contract owner by
  sharing the `PauseExecutor` capability.
  Please see [delegation process] for details.
  * **Blocklisting: BlocklistExecutor and Blocklister**: If a resource (`Vault`, `Minter`, etc)
  has been flagged and required to be blocked, the `Blocklister` will be able to such resource to
  the `blocklist`. The contract owner shares the `BlocklistExecutor` capabilities with the
  Blocklist to delegate such action.
  Blocklisted resources are prevented from minting, burning, transferring or approving token transfers.
  Please see [delegation process] for details.
  * **Allowance: Vault**: In additiont to `FungibleToken` interfaces,
  the `Vault` is enhanced with with features such as `VaultUUID` and `Allowance`.

All of the functionality above is equipped with [on-chain multi-signature support].
[delegation process]: (doc/resource-interactions.md)
[`FiatToken`]: https://github.com/flow-usdc/flow-usdc/blob/main/contracts/FiatToken.cdc
[`FiatTokenInterface`]: https://github.com/flow-usdc/flow-usdc/blob/main/contracts/FiatTokenInterface.cdc
[`FungibleToken`]: https://docs.onflow.org/core-contracts/fungible-token/
[on-chain multi-signature support]: https://github.com/flow-hydraulics/onchain-multisig

## Table of Contents

* [Usage](#usage)
  * [On Testnet](#on-testnet)
  * [Environment Variables](#environment-variables)
  * [Testing Script](#testing-script)
* [Install](#install)
  * [Prerequisites](#prerequisites)
  * [Installing `flow-usdc`](#installing-flow-usdc)
* [Contributing](#contributing)
  * [Repo Layout](#repo-layout)
* [License](#license)

## Usage

The USDC Flow token is continuously deployed to testnet. It is also available to developers
for local use and testing.

### On Testnet

The (work in progress) USDC Token contract is currently deployed to the account
[`0x8aef704f5bca27a1`](https://flow-view-source.com/testnet/account/0x8aef704f5bca27a1/) on the
Flow testnet.

<!-- TODO: Examples -->

### Environment Variables

A typical configuration file will look something like the following:

```shell
TOKEN_ACCOUNT_KEYS= [ 64 byte private key ]
TOKEN_ACCOUNT_PK= [128 byte public key with same seed as TOKEN_ACCOUNT_KEYS]

# Emulator settings
# --------
# NETWORK=emulator
# RPC_ADDRESS=localhost:3569
# TOKEN_ACCOUNT_ADDRESS=[ emulator account generated from TOKEN_ACCOUNT_PK ]
# FUNGIBLE_TOKEN_ADDRESS=ee82856bf20e2aa6

# Testnet
# -------
NETWORK=testnet
RPC_ADDRESS=access.devnet.nodes.onflow.org:9000
TOKEN_ACCOUNT_ADDRESS= [ testnet account generated from TOKEN_ACCOUNT_PK ]
FUNGIBLE_TOKEN_ADDRESS=9a0766d93b6608b7
```

To generate the necessary values, choose a 32 byte seed (can use a random hex string), and
pass it to the `flow keygen` tool:

```bash
SEED=$(hexdump -n 16 -e '4/4 "%08X" 1 "\n"' /dev/random) # Non-safe but usable random numbers
TOKEN_ACCOUNT_KEYS=$(flow keys generate --seed="$SEED" -o inline --filter=Private)
TOKEN_ACCOUNT_PK=$(flow keys generate --seed="$SEED" -o inline --filter=Private)
TOKEN_ACCOUNT_ADDRESS=$(flow accounts create --key="$TOKEN_ACCOUNT_PK" -o inline --filter=Address)
```

You can see this in action in our testing script, described in the next section.

### Testing Script

In order to mitigate skew between emulator testing and testnet testing, this repo provides a
script, `./test/test.sh`, that automates all of the necessary setup and teardown for running the Go
tests. This includes running and stopping the Flow emulator if necessary. Once the environment
variables described above are properly set up, you can simply run this script from the repo
root.

```bash
./test/test.sh
```

## Install

Theoretically, you should only need the Cadence code in this repo, but if you're looking to
try it out locally or test, you will a couple other tools. If you're looking to simply
interact with the contract on Testnet, you can skip ahead to the ["on testnet"](#on-testnet)
section.

### Prerequisites

To run and test the code in this repo, it's required that you install:

* The [Flow CLI](https://docs.onflow.org/flow-cli/) tool, for manual usage
* The [Go](https://golang.org/doc/install) programming language, to run the automated tests

### Installing `flow-usdc`

Once you have `flow` and `go` installed, then simply clone the repo to get started:

```bash
git clone https://github.com/flow-usdc/flow-usdc
```

## Contributing

Issues and PRs accepted. Over time more details will be added here.

### Repo Layout

* `contracts` - contains all of the contracts and the scripts required to interact with them
* `env.example` - example file to be populated with values and copied to `./test/.env`
* `flow.json` - configuration file for the `flow` CLI tool.
* `test` - Test code in Golang.
* `transactions` - contains examples of transactions one can perform with the contract

#### Documentation

Some documentation is auto-generated from comments and code.
Run the command(s) below to update the docs:

```bash
$ make -B doc/TRANSACTIONS.md
```

## License

[MIT License](./LICENSE), Copyright (c) 2018-2021 CENTRE SECZ
