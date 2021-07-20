# USD Coin (USDC), on Flow _(flow-usdc)_

> A `FungibleToken`-compatible fiat coin on Flow, with additional support for pausing and blocklisting.

<!-- markdownlint-configure-file { "MD013": { "line_length": 100 } } -->

[![standard-readme compliant](https://img.shields.io/badge/readme%20style-standard-lightgreen.svg?style=flat-square)](https://github.com/RichardLitt/standard-readme)
[![Tests](https://github.com/flow-usdc/flow-usdc/actions/workflows/tests-main.yml/badge.svg)](https://github.com/flow-usdc/flow-usdc/actions/workflows/tests-main.yml)
[![Static Analysis](https://github.com/flow-usdc/flow-usdc/actions/workflows/static-analysis.yml/badge.svg)](https://github.com/flow-usdc/flow-usdc/actions/workflows/static-analysis.yml)

<!-- TODO: Banner? -->
<!-- TODO: Background? -->

This repo contains the implementation of USDC in Cadence, on the Flow Blockchain. This is based
mainly on Centre's [`FiatToken`] standard. The standard offers a number of capabilities. When
possible, we refer back to the Solidity equivalent in parentheses.

<!-- TODO: Link to interface resources here -->

* **`FungibleToken` (a.k.a. ERC20) compatible**: The FiatToken implements the Flow core
[`FungibleToken`] interface. This interface provides the baseline Minter, Burner, and Vault
(a.k.a Ownable) resources.
* **Pausable**: The entire contract can be frozen, in case a serious bug is found or there is a
serious key compromise. No transfers can take place while the contract is paused. Access to the
pause functionality is controlled by the `Pauser` resource (a.k.a pausing address).
* **Blocklist**: The contract can blocklist certain addresses which will prevent those addresses
from transferring or receiving tokens. Access to the blocklist functionality is controlled by the
Blocklister resource (a.k.a. blacklister address).

For more information, please see the [Requirements doc](./doc/requirements.md).

[`FiatToken`]: https://github.com/centrehq/centre-tokens
[`FungibleToken`]: https://docs.onflow.org/core-contracts/fungible-token/

## Table of Contents

* [Install](#install)
  * [Prerequisites](#prerequisites)
  * [Installing `flow-usdc`](#installing-flow-usdc)
* [Usage](#usage)
  * [On Testnet](#on-testnet)
  * [Environment Variables](#environment-variables)
  * [Testing Script](#testing-script)
* [Contributing](#contributing)
  * [Repo Layout](#repo-layout)
* [License](#license)

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
