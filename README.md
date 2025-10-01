# Gensyn Token [![Foundry][foundry-badge]][foundry]
[foundry]: https://getfoundry.sh/
[foundry-badge]: https://img.shields.io/badge/Built%20with-Foundry-FFDB1C.svg

## Overview
The `GensynToken` is an upgradeable ERC20 token that will play a central role in the Gensyn Protocol. Aside from its standard ERC20 functionality, it also supports:
- Burning
- Voting
- Gasless Approvals
- Role Based Access Control
- UUPS Upgradeability

Also note that:
- The `GensynToken` will sit behind a `ERC1967Proxy`.
- The entire supply of `GensynTokens` will be minted when the implementation is initialization. No other mints will ever occur.
- The `GensynToken` currently only has one role: `DEFAULT_ADMIN_ROLE` (which is owned by the `TimelockController`).
- The `TimelockController` will enforce a minimum delay of 7 days on all actions on the `GensynToken`.

## Installation

This project was built using [Foundry](https://book.getfoundry.sh/). Refer to Foundry installation instructions [here](https://github.com/foundry-rs/foundry#installation). Installing Foundry is a prerequisite for installing the project. After installing Foundry, run the following commands to install the project locally:
```sh
git clone https://github.com/gensyn-ai/gensyn-token.git gensyn-token
cd gensyn-token
forge install
```

## Deployment
To successfully deploy the `GensynToken`, complete the following steps:

### 1. Set up Env
Create a `.env` file at the top level of the project, with the same configuration as [.env.example](.env.example). Then, simply replace the dummy values with your desired values.

### 2. Set up Private Key
Make sure to store your Private Key locally inside of a `cast wallet`. This is the safest method to store the deployment Private Key, as it allows for decrypted data storage without necessitating a file (which could be accidentally pushed to a public repo). To import your Private Key into a `cast wallet`, run the following command:
```bash
cast wallet import ${ACCOUNT_NAME} --interactive
```
And then simply follow the prompts. The `ACCOUNT_NAME` is completely up to you. It is simply what foundry will use to identify your private key. For example, you could run:
```bash
cast wallet import alice --interactive
```

### 3. Deploy
You can run the following command to `deploy` a contract:
```bash
make deploy contract=${CONTRACT} network=${NETWORK} from=${ACCOUNT_NAME}
```

#### Legend
- `CONTRACT`: The contract you want to interact with.
- `NETWORK`: The network you want to interact with.
- `ACCOUNT_NAME`: The account you want to broadcast transactions from.

#### Current Options
- `CONTRACT`
    - `GensynToken`
- `NETWORK`
    - `gensyn-testnet`
    - `gensyn-mainnet`

So you could run, for example:
```bash
make deploy contract=GensynToken network=gensyn-testnet from=bob
```

## Tests
Tests were written to ensure the following functionality is working correctly:
- `GensynToken`
    - Deployment, Transfer, TransferFrom (`ERC20Upgradeable`)
    - Burn, BurnFrom (`ERC20BurnableUpgradeable`)
    - Delegate, DelegateBySig (`ERC20VotesUpgradeable`)
    - Permit (`ERC20PermitUpgradeable`)
    - GrantRole (`AccessControlUpgradeable`)
    - Initialize, UpgradeToAndCall (`UUPSUpgradeable`)
    - Schedule, Execute (`Timelock`)

## Notes
- All Dependencies are pinned to their latest release (see [foundry.lock](./foundry.lock))