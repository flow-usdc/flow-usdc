# The CENTRE Fiat Token, on Flow _(flow-usdc)_

> An implementation of the CENTRE Fiat Token in Cadence, on the Flow Blockchain.

<!-- markdownlint-configure-file { "MD013": { "line_length": 100 } } -->

[![standard-readme compliant](https://img.shields.io/badge/readme%20style-standard-lightgreen.svg?style=flat-square)](https://github.com/RichardLitt/standard-readme)
[![Tests](https://github.com/flow-usdc/flow-usdc/actions/workflows/tests-main.yml/badge.svg)](https://github.com/flow-usdc/flow-usdc/actions/workflows/tests-main.yml)
[![Static Analysis](https://github.com/flow-usdc/flow-usdc/actions/workflows/static-analysis.yml/badge.svg)](https://github.com/flow-usdc/flow-usdc/actions/workflows/static-analysis.yml)

<!-- TODO: Banner? -->

A [`FiatToken`] on the Flow blockchain, written in Cadence,
which implements interfaces defined in the following contracts:

* **[`FungibleToken`] (a.k.a. ERC20)**, which provides the baseline Vault (a.k.a Ownable) 
resource and interfaces for compatibility.
* **[OnChainMultiSig]**, are implemented for `MasterMinter`, `MinterController`,
`Minter`, `Pauser`, `Blocklister`, and `Vault` resources which allows
for multiple signatures to authorize transactions without time restrictions.

`FiatToken` includes the following admin functionality that makes use
of the `OnChainMultiSig` functionality to execute:

  * **Delegated Minting: MasterMinter, MinterControllers and Minters**:
  `MasterMinter` can set states in `managedMinter` to delegate
  `MinterControllers` to control the allowance / removal of a `Minter`.
  Both `MinterController` and `Minter` resources are created by the users
  and the unique resource uuid is stored in the `managedMinter` and `minterAllowances` states.
  Please see [delegation process](./doc/resource-interactions.md) for details.
  * **Pausing and Unpausing: PauseExecutor and Pauser**: If a situation like a major bug discovery
  or a serious key compromise,
  a `Pauser` will be able to halt all transfers and approvals contract-wide,
  until a mitigation takes place.
  `Pauser` is granted the capability to pause / unpause a contract by the contract owner by
  sharing the `PauseExecutor` capability.
  Please see [delegation process](./doc/resource-interactions.md) for details.
  * **Blocklisting: BlocklistExecutor and Blocklister**: If a resource (`Vault`, `Minter`, etc)
  has been flagged and required to be blocked, the `Blocklister` will be able to such resource to
  the `blocklist`. The contract owner shares the `BlocklistExecutor` capabilities with the
  Blocklist to delegate such action.
  Blocklisted resources are prevented from minting, burning, transferring or approving token transfers.
  Please see [delegation process](./doc/resource-interactions.md) for details.
  * **Allowance: Vault**: In addition to `FungibleToken` interfaces,
  the `Vault` is enhanced with with the `Allowance` which allows the vault owner to set a withdrawal
  limit for other vaults.

[`FiatToken`]: https://github.com/flow-usdc/flow-usdc/blob/main/contracts/FiatToken.cdc
[`FungibleToken`]: https://docs.onflow.org/core-contracts/fungible-token/
[OnChainMultiSig]: https://github.com/flow-hydraulics/onchain-multisig

## Usage

The `FiatToken` contract is currently deployed to the following accounts:

| Network         | Contract Address     |
| --------------- | -------------------- |
| Testnet         | `0xa983fecbed621163` |
| Mainnet         | `0xb19436aae4d94622` |

The `OnChainMultiSig` contract is currently deployed to the following accounts:

| Network         | Contract Address     |
| --------------- | -------------------- |
| Testnet         | `0x5a5b0a73a29e83f1` |
| Mainnet         | `0x220c1b4155f86f2f` |

### Transactions and Scripts

You can interact with the `FiatToken` contract using **transactions** and **scripts**. Examples
of each can be found in the `doc/` folder:

* [Transactions](./doc/TRANSACTIONS.md)
* [Scripts](./doc/SCRIPTS.md)

### Beyond Usage

If you're developing an app using the `FiatToken` contract, you should only need to reference the
Cadence code in this repo. However, if you're looking to try it out locally or run the tests,
you will a couple other tools.

## Install

### Prerequisites

To run and test the code in this repo, it's required that you install:

* The [Flow CLI](https://docs.onflow.org/flow-cli/) tool, for manual usage
* The [Go](https://golang.org/doc/install) programming language, to run the automated tests

### Installing `flow-usdc`

Once you have `flow` and `go` installed, then simply clone the repo to get started:

```bash
git clone https://github.com/flow-usdc/flow-usdc
```

[`0xa983fecbed621163`]: https://flow-view-source.com/testnet/account/0xa983fecbed621163/

### Environment Variables

For local testing via the Flow emulator, a typical configuration file will look something like:

```shell
# Emulator settings
# --------
NETWORK=emulator
RPC_ADDRESS=localhost:3569
TOKEN_ACCOUNT_ADDRESS=[ emulator account generated from TOKEN_ACCOUNT_PK ]
FUNGIBLE_TOKEN_ADDRESS=ee82856bf20e2aa6
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

### Deploying to Testnet for the first time

1. Once account private / public key pair has been generated and they are saved in .env,
`make testnet-create-accounts` will create all the accounts and signed by `testnet-owner`
2. When new accounts have been created, add those new addresses to `flow.json`.
3. Transfer some flow tokens to the created account via `make testnet-transfer-flow-tokens`
4. You can now run make test

### Testing Script

In order to mitigate skew between emulator testing and testnet testing, this repo provides a
script, `./test/test.sh`, that automates all of the necessary setup and teardown for running the Go
tests. This includes running and stopping the Flow emulator if necessary. Once the environment
variables described above are properly set up, you can simply run this script from the repo
root.

```bash
./test/test.sh
```

Additional testing information can be found in [`doc/tests.md`](./doc/tests.md)

## Contributing

Issues and PRs accepted. Over time more details will be added here.

### Repo Layout

* `contracts` - contains all of the contracts and the scripts required to interact with them
* `doc` - contains manual and auto-generated documentation for contracts, scripts, and transactions
* `lib/go` - Test code in Golang.
* `scripts` - contains examples of scripts used to interact with the contract
* `transactions` - contains examples of transactions one can perform with the contract
* `env.example` - example file to be populated with values and copied to `./test/.env`
* `flow.json` - configuration file for the `flow` CLI tool.

## License

[MIT License](./LICENSE), Copyright (c) 2018-2021 CENTRE SECZ
