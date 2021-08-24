# Testing structure

<!-- markdownlint-configure-file { "MD013": { "line_length": 200} } -->

## Overview

This document highlights the testing structure for the resources in the `FiatToken` contract.

Each directory in `lib/go` are grouped by resources that perform some features,
i.e. `lib/go/blocklist` tests the `Blocklister` and the `BlocklistExecutor` by performing
blocklisting / unblocklisting.

Within each feature, tests are first done with a single signer directly calling the
functions of the resource. Then the integration with `OnChainMultiSig` tests are performed.

`OnChainMultiSig` tests are performed mainly to ensure the implementation of `OnChaiMultiSig.PublicSigner`
is correct. Details of the internal workings of the `OnChainMultiSig.Manager` is found [here].

### OnChainMultiSig tests

1. First test performs a function provided by the resource, such as the `pause` function in `Pauser`.
First signer (w500_1) will use the `addNewPayload` function to add the new payload.
The first signer will not have enough weight and the first `executeTx` call should fail.
Second signer (w500_2) will use the `addPayloadSignature` function to add its support.
The second `executeTx` call should execute the payload.

2. Subsequent few tests will test the rest of the functions provided by the resources.
The fist signer (w1000) will already have enought weight for the transaction to be
executed when `executeTx` is called.

3. The third to last test tests that methods not supported by the resource does not execute.

4. The last two tests test that the keys can be added / removed in the `OnChainMultiSig.Manager`
for the resource

### Test accounts

Accounts generated in flow are [deterministic].
The names of the account in `flow.json` aims to aid the the readibility when testing.

- owner:  owner of the contract (owner of MasterMinter, BlocklistExecutor and PauseExecutor)
- vaulted-account: account has a Vault
- non-vaulted-account: account does not have a Vault
- pauser: account has Pauser resource and will be given capability
- non-pauser: account has no given capability
- blocklister:  account has Blocklsiter and will be given capability
- non-blocklister: account has no given capability
- allowance: account has allowance set for a Vault
- non-allowance: account has no allowance set for any Vault
- minter: account has Minter resource and controller can set allowance
- minterContorller*: account has MinterController resource and can be delegated by MasterMinter
- w-(weight)-(num): accounts have set weight, 1000 being the required weight for execution
and num(ber) of account of the same weight.
*All of these Accounts public keys are registered in all the multisig supported resources*
- non-multisig-account: not registered in any resources

[here]: https://github.com/flow-hydraulics/onchain-multisig
[deterministic]: https://docs.onflow.org/concepts/accounts-and-keys/
