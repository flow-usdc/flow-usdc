# Requirements

This documents the requirements for implementing USDC on Flow with Cadence.
Specifically, the implementation must be compatible with both the [Flow Fungible Token Standard] and the [Centre Tokens] and by extension [ERC20].
Compatible means interfaces, events and functionality have to be compatible.

[Flow Fungible Token Standard]: https://github.com/onflow/flow-ft
[Centre Tokens]: https://github.com/centrehq/centre-tokens/tree/master/doc
[ERC20]: https://docs.openzeppelin.com/contracts/2.x/api/token/erc20#IERC20

## Token Security & Functionality Requirements

### Asset implementation

- A version of the USDC asset has to be implemented on mainnet for security & functionality assessment.

Functionality – Replication of existing USDC capabilities.  The proposed USDC implementation must be audited to ensure it supports the following functionality:

- Blacklisting / freezing as well as unblacklisting / thawing (mandatory)
- Multi-signature (mandatory)
- Multi-issuer - multiple addresses can mint tokens (mandatory)
- Minter Restrictions - minters are restricted in some fashion. There's either a
        - mint allowance (minters can only mint some total quantity of tokens) or
        - a combination of expiry (minters can only mint until a certain block height) and
        - address restriction (minters can only mint to certain addresses). (mandatory)
- Cold storage - provision for offline signing (mandatory)
- [Smart Contracts Only] Upgradability (mandatory)
- [Smart Contracts Only] Pausability (mandatory)
- Gas-less spends (optional)
- Acceptance criteria: Fully replicated functionality

### Security

The proposed USDC implementation must undergo a security audit.

Implementation must use an audited token specification.

Implementation audit confirms it is a valid implementation of the specification.

All admin keys conform to the existing policy on administrator keys for USDC with proper role definition and clarity of custody and authorization of use.

Acceptance criteria: No open Critical or High findings

## Main Token Contract Details

### Interfaces

| Interface                          | Arg(s)                                  | Return  | Event(s)                  | TX?  | FlowFT mapping   |
| --:                                | ---:                                    | ---:    | ---:                      | ---: | ---:             |
| totalSupply                        | N/A                                     | amount  | N/A                       | N    | totalSupply      |
| balanceOf                          | account                                 | amount  |                           | N    | balance          |
| allowance                          | owner, spender                          | amount  |                           | N    |                  |
| transfer                           | recipient, amount                       | bool    | Transfer                  | Y    | deposit/withdraw |
| approve                            | spender, amount                         | bool    | Approve                   | Y    | deposit/withdraw |
| transferFrom                       | sender, recipient, amount               | bool    | Transfer                  | Y    | deposit/withdraw |
| ---                                | ---                                     | ---     | ---                       | ---  | ---              |
| mint                               |                                         |         | Mint, Transfer            | Y    |                  |
| burn                               |                                         |         | Burn, Transfer            | Y    |                  |
| isMinter                           | account                                 | bool    | N/A                       | N    |                  |
| minterAllowance                    | minter                                  | amount  | N/A                       | N    |                  |
| configureMinter                    | minter, minterAllowedAmount             | bool    | MinterConfigured          | Y    |                  |
| removeMinter                       | minter                                  | bool    | MinterRemoved             | Y    |                  |
| updateMasterMinter                 | newMasterMinter                         | N/A     | MasterMinterChanged       | Y    |                  |
| ---                                | ---                                     | ---     | ---                       | ---  | ---              |
| isBlackListed                      | account                                 | bool    | N/A                       | N    |                  |
| blacklist                          | account                                 | N/A     | Blacklisted               | Y    |                  |
| unBlacklist                        | account                                 | N/A     | UnBlacklisted             | Y    |                  |
| updateBlacklister                  | newBlacklister                          | N/A     | BlacklisterChanged        | Y    |                  |
| ---                                | ---                                     | ---     | ---                       | ---  | ---              |
| pause                              | N/A                                     | N/A     | Pause                     | Y    |                  |
| unpause                            | N/A                                     | N/A     | Unpause                   | Y    |                  |
| updatePauser                       | newPauser                               | N/A     | PauserChanged             | Y    |                  |
| ---                                | ---                                     | ---     | ---                       | ---  | ---              |
| owner                              |                                         | owner   |                           | N    |                  |
| transferOwnership                  | newOwner                                | N/A     | OwnershipTransferred      | Y    |                  |
| setOwner (internal)                | newOwner                                | N/A     |                           | Y    |                  |
| ---                                | ---                                     | ---     | ---                       | ---  | ---              |
| rescuer                            | N/A                                     | rescuer | N/A                       | N    |                  |
| rescueERC20                        | tokenContract, to, amount               | N/A     | N/A                       | Y    |                  |
| updateRescuer                      | newRescuer                              | N/A     | RescuerChanged            | Y    |                  |
| ---                                | ---                                     | ---     | ---                       | ---  | ---              |
| increaseAllowance                  | spender, increment                      | bool    | Approval (indirect)       | Y    |                  |
| decreaseAllowance                  | spender, decrement                      | bool    | Approval (indirect)       | Y    |                  |
| authorizationState                 | authorizer, nonce                       | bool    | N/A                       | N    |                  |
| transferWithAuthorization          | from, to, value, validity, n, sig       | N/A     | AuthorizationUsed (i)     | Y    |                  |
| cancelAuthorization                | from, to, value, validity, n, sig       | N/A     | AuthorizationCanceled (i) | Y    |                  |
| recieveWithAuthorization           | from, to, value, validity, n, sig       | N/A     | AuthorizationUsed (i)     | Y    |                  |
| transferWithMultipleAuthorizations | params, sigs, atomic                    | bool    | Transfer (indirect)       | Y    |                  |
| ---                                | ---                                     | ---     | ---                       | ---  | ---              |
| nonces                             | owner                                   | nonce   | N/A                       | N    |                  |
| permit                             | owner, spender, value, deadline, n, sig | N/A     | Approval (indirect)       | Y    |                  |
| ---                                | ---                                     | ---     | ---                       | ---  | ---              |
| version                            | N/A                                     | version | N/A                       | N    |                  |

### Events

| Event                | Args                        | FlowFT mapping |
| --:                  | ---:                        | ---:           |
| Transfer             | from, to, value             |                |
| Approval             | owner, spender, value       |                |
| ---                  | ---                         | ---            |
| Mint                 | minter, to, amount          |                |
| Burn                 | minter, amount              |                |
| MinterConfigured     | minter, minterAllowedAmount |                |
| MinterRemoved        | oldMinter                   |                |
| MasterMinterChanged  | newMasterMinter             |                |
| ---                  | ---                         |                |
| Blacklisted          | account                     |                |
| UnBlacklisted        | account                     |                |
| BlacklisterChanged   | newBlacklister              |                |
| ---                  | ---                         | ---            |
| Pause                | N/A                         |                |
| Unpause              | N/A                         |                |
| PauserChanged        | newPauser                   |                |
| ---                  | ---                         | ---            |
| OwnershipTransferred | owner, newOwner             |                |
| ---                  | ---                         | ---            |
| RescuerChanged       | newRescuer                  |                |
| ---                  | ---                         | ---            |
| AuthorizationUsed    | authorizer, nonce           |                |
| AuthorizationCanceled| authorizer, nonce           |                |

## Minting in USDC Details

Follows a owner -> controller -> worker (minter) pattern.
Please see [MasterMinter details] for details.

Below is a simple diagram of where the control lies.
Owner sets the controllers and controllers sets the minters.

```sh

|--Controller.sol--|--MintController --|
        |--- controller_1 ---| 
        |                    | - minter1
owner --|--- controller_2 ---| 
        |--- controller_3 ---| 
        |                    | - minter2
        |--- controller_4 ---|  
```

[MasterMiner details]: https://github.com/centrehq/centre-tokens/blob/master/doc/masterminter.md

### Master Minter Interfaces

The MasterMinter contract inherits MintController, which in turn inherits Controller.
`mintManager` is just the FiatToken contract (since it impl `MinterManagerInterfaces`).

| Interface                | Arg(s)             | Return | Event(s)                   | TX?  | FlowFT mapping |
| --:                      | ---:               | ---:   | ---:                       | ---: | ---:          |
| configureController      | controller, minter | N/A    | ControllerConfigured       | Y    |       |
| removeController         | controller         | N/A    | ControllerRemoved          | Y    |       |
| setMinterManager         | mintManager        | N/A    | MintManagerSet             | Y    |       |
| configureMinter*         | allowance          | bool   | MinterConfigured           | Y    |       |
| incrementMinterAllowance | allowanceIncrement | bool   | MinterAllowanceIncremented | Y    |       |
| decrementMinterAllowance | allowanceDecrement | bool   | MinterAllowanceDecremented | Y    |       |
| removeMinter             | N/A                | bool   | MinterRemoved              | Y    |       |

`*`: these are called by controller on the MasterMinter, who will call the main fiat token contract.
Hence might seem duplicate of the main token contract interfaces (minus minter functions since 1 minter per controller)

### Master Minter Events

| Event                      | Args                                 | FlowFT mapping |
| --:                        | ---:                                 | ---:           |
| ControllerConfigured       | controller, worker                   |           |
| ControllerRemoved          | controller                           |           |
| MinterConfigured           | controller, minter, newAllowance     |           |
| MinterAllowanceIncremented | controller, minter inc, newAllowance |           |
| MinterAllowanceDecremented | controller, minter dec, newAllowance |           |
| MinterRemoved              | controller, minter                   |           |

#### TODOS

- [x] IERC20 non-optional only

- [x] contracts/minting
    - [x] controller
    - [x] masterminter
    - [x] Mintercontroller
    - [x] mintermanagementInterface
- [x] V1
- [x] V1.1
- [x] V2 - minus migration & lostandfound
- [ ] upgradability
- [ ] util
