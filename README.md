## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

-   **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
-   **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
-   **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
-   **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

# Gensyn Token Project

This project implements the Gensyn (GYN) ERC20 token with advanced features including lockup periods, vesting schedules, and merkle-based token distribution.

## Overview

The Gensyn token ecosystem consists of several smart contracts:

- **GensynToken**: The main ERC20 token with pausable functionality
- **GensynVestingManager**: Manages vesting schedules for team members and insiders
- **GensynVestingWallet**: Individual vesting wallets with cliff functionality
- **MerkleDistributor**: Efficient token distribution using merkle proofs for airdrops

## Features

### Token Features
- Standard ERC20 functionality with permit support
- Pausable for emergency situations
- Owner can mint additional tokens
- Total supply: 1,000,000,000 GYN tokens

### Vesting Features
- 1-year cliff period before any tokens are released
- Monthly vesting over a total period of 3 years
- Individual vesting wallets for each beneficiary
- Batch creation of multiple vesting schedules
- View functions to track vesting progress

### Distribution Features
- Merkle-tree based airdrops for efficient gas usage
- Individual MerkleDistributor contracts for each airdrop round
- Emergency withdrawal mechanisms for unclaimed tokens
- Claim verification and tracking

## Project Structure

```
├── src/                          # Smart contracts
│   ├── GensynToken.sol          # Main ERC20 token
│   ├── GensynVestingManager.sol # Vesting management
│   ├── GensynVestingWallet.sol  # Individual vesting wallet
│   └── MerkleDistributor.sol    # Merkle-based distribution
├── test/                        # Test files
│   ├── GensynToken.t.sol
│   ├── GensynVestingManager.t.sol
│   └── MerkleDistributor.t.sol
├── script/                      # Deployment scripts
│   └── DeployGensyn.s.sol
└── lib/                        # Dependencies
    ├── forge-std/
    ├── openzeppelin-contracts/
    └── merkle-distributor/
```

## Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd gensyn-token
```

2. Install dependencies:
```bash
forge install
```

3. Build the project:
```bash
forge build
```

4. Run tests:
```bash
forge test
```

## Deployment

### Local Deployment

1. Start a local blockchain:
```bash
anvil
```

2. Deploy contracts:
```bash
forge script script/DeployGensyn.s.sol --rpc-url http://localhost:8545 --private-key <your-private-key> --broadcast
```

### Testnet/Mainnet Deployment

1. Set environment variables:
```bash
export PRIVATE_KEY=<your-private-key>
export RPC_URL=<your-rpc-url>
```

2. Deploy:
```bash
forge script script/DeployGensyn.s.sol --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast --verify
```

## Usage Examples

### Creating Vesting Schedules

```solidity
// Create a vesting wallet for a team member
address beneficiary = 0x...;
uint256 amount = 100000 * 10**18; // 100,000 tokens
uint256 startTime = block.timestamp;

address vestingWallet = vestingManager.createVestingWallet(
    beneficiary,
    amount,
    startTime
);

// Create multiple vesting schedules at once
address[] memory beneficiaries = [0x..., 0x...];
uint256[] memory amounts = [100000 * 10**18, 50000 * 10**18];
uint256[] memory startTimes = [block.timestamp, block.timestamp];

vestingManager.createMultipleVestingWallets(
    beneficiaries,
    amounts,
    startTimes
);
```

### Token Distribution (Airdrops)

```solidity
// Deploy a new MerkleDistributor for an airdrop
bytes32 merkleRoot = 0x...; // Generated from merkle tree of eligible recipients
address owner = msg.sender; // Contract owner who can emergency withdraw

MerkleDistributor airdropDistributor = new MerkleDistributor(
    address(gensynToken),
    merkleRoot,
    owner
);

// Transfer tokens to the distributor
gensynToken.transfer(address(airdropDistributor), totalAirdropAmount);

// Users claim their tokens with merkle proofs
uint256 index = 0;
address account = 0x...;
uint256 amount = 1000 * 10**18;
bytes32[] memory merkleProof = [...];

airdropDistributor.claim(index, account, amount, merkleProof);
```

## Token Distribution Strategy

The Gensyn token uses two distinct distribution mechanisms:

### 1. Vesting (Team/Insiders)
- **Purpose**: Long-term incentive alignment for team members and early investors
- **Mechanism**: Direct transfer to `GensynVestingWallet` contracts
- **Schedule**: 1-year cliff + monthly vesting over 3 years
- **Management**: Centralized through `GensynVestingManager`

### 2. Airdrops (Community/Public)
- **Purpose**: Community distribution and user acquisition
- **Mechanism**: Deploy individual `MerkleDistributor` contracts
- **Schedule**: Immediate claiming (no vesting)
- **Benefits**: Gas-efficient, users pay for their own claims

```
Distribution Flow:

┌─────────────┐    Vesting     ┌──────────────────┐    Cliff+Vesting    ┌─────────────┐
│   Custodian │──────────────→ │ GensynVestingMgr │────────────────────→ │ Team Tokens │
│             │                └──────────────────┘                     └─────────────┘
│             │
│             │    Airdrop     ┌──────────────────┐    Immediate Claim  ┌─────────────┐
│             │──────────────→ │ MerkleDistributor│────────────────────→ │Public Tokens│
└─────────────┘                └──────────────────┘                     └─────────────┘
```

## Vesting Schedule Details

- **Cliff Period**: 1 year (365 days)
- **Total Vesting Period**: 3 years (1,095 days)
- **Vesting Frequency**: Monthly (30 days)

### Vesting Timeline Example

For a 100,000 token allocation:
- **Year 0-1**: 0 tokens released (cliff period)
- **Year 1**: ~33,333 tokens released (1/3 of total)
- **Year 2**: ~66,666 tokens released (2/3 of total)  
- **Year 3**: 100,000 tokens released (100% of total)

## Security Features

- **Ownable**: Critical functions restricted to contract owner
- **Pausable**: Emergency pause functionality for the token
- **Reentrancy Protection**: Built into OpenZeppelin contracts
- **Access Control**: Role-based permissions
- **Emergency Withdrawals**: Recovery mechanisms for stuck tokens

## Testing

The project includes comprehensive tests covering:

- Token basic functionality (transfer, approve, etc.)
- Pausable functionality
- Vesting schedule creation and execution
- Merkle distribution claiming
- Access control and security features
- Edge cases and error conditions

Run tests with:
```bash
forge test -v              # Basic test run
forge test -vv             # More verbose output
forge test --gas-report    # Include gas usage
```

## Gas Optimization

The contracts are optimized for gas efficiency:
- Merkle distributions reduce gas costs for large airdrops
- Batch operations for multiple vesting schedules
- Efficient storage patterns
- Minimal external calls

## License

This project is licensed under the MIT License.

## Security Considerations

⚠️ **Important**: This code is for demonstration purposes. Before deploying to mainnet:

1. Conduct thorough security audits
2. Test extensively on testnets
3. Consider additional security measures
4. Review all access controls
5. Implement proper governance mechanisms

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Ensure all tests pass
6. Submit a pull request

## Support

For questions or issues, please open an issue in the repository or contact the development team.
