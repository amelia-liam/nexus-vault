# NexusVault - Advanced sBTC Yield Protocol

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Stacks](https://img.shields.io/badge/Stacks-Blockchain-purple)](https://stacks.co)
[![Clarity](https://img.shields.io/badge/Smart%20Contract-Clarity-blue)](https://clarity-lang.org)

A secure, efficient yield farming protocol for sBTC on the Stacks blockchain featuring time-locked deposits, dynamic rewards, and comprehensive position management.

## 🚀 Features

### Core Functionality

- **Time-Locked Deposits**: Stake sBTC with customizable lock periods (1 month to 5 years)
- **Dynamic Yield Rewards**: Base APR with lock duration bonuses up to 25%
- **Position Management**: Create, monitor, and close staking positions
- **Automatic Compounding**: Claim rewards while maintaining your staking position

### Security Features

- **Input Validation**: Comprehensive validation for all user inputs
- **Overflow Protection**: Safe arithmetic operations with bounds checking
- **Emergency Controls**: Protocol pause and emergency withdrawal capabilities
- **Access Control**: Owner-only administrative functions

### Advanced Features

- **Lock Bonus System**: Additional rewards for longer commitment periods
- **User Statistics**: Lifetime tracking of staking and rewards
- **Protocol Analytics**: Daily snapshots and comprehensive metrics
- **Flexible Administration**: Configurable reward rates and protocol parameters

## 📊 Protocol Specifications

### Parameters

| Parameter | Value | Description |
|-----------|-------|-------------|
| Minimum Stake | 0.001 sBTC (100,000 satoshis) | Minimum amount required to create a position |
| Lock Period Range | 1 month - 5 years | Supported lock duration range |
| Base APR | 5% (configurable) | Default annual percentage rate |
| Max APR | 100% | Maximum allowed APR |
| Lock Bonus | Up to 25% | Additional yield for longer locks |
| Precision Factor | 10,000 basis points | Calculation precision for percentages |

### Lock Bonus Structure

- **1 Year Lock**: +5% bonus APR
- **2 Year Lock**: +10% bonus APR
- **3 Year Lock**: +15% bonus APR
- **4 Year Lock**: +20% bonus APR
- **5 Year Lock**: +25% bonus APR (maximum)

## 🛠 Installation & Setup

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) installed
- Node.js 16+ for testing
- TypeScript for test development

### Clone the Repository

```bash
git clone https://github.com/amelia-liam/nexus-vault.git
cd nexus-vault
```

### Install Dependencies

```bash
npm install
```

### Run Tests

```bash
# Check contract syntax
clarinet check

# Run the test suite
npm test
```

## 📖 Usage Guide

### Creating a Staking Position

```clarity
;; Create a 1-year staking position with 1 sBTC
(contract-call? .nexus-vault create-position 
  .sbtc-token 
  u100000000 ;; 1 sBTC in satoshis
  u52560)     ;; ~1 year in blocks
```

### Claiming Rewards

```clarity
;; Claim accumulated rewards
(contract-call? .nexus-vault claim-rewards .sbtc-token)
```

### Closing a Position

```clarity
;; Close position after lock period expires
(contract-call? .nexus-vault close-position .sbtc-token)
```

### Checking Position Status

```clarity
;; Get user's current position
(contract-call? .nexus-vault get-user-position tx-sender)

;; Check available rewards
(contract-call? .nexus-vault get-available-rewards tx-sender)

;; Check if position is unlocked
(contract-call? .nexus-vault is-position-unlocked tx-sender)
```

## 🔍 Contract Interface

### Public Functions

#### Core Staking Functions

- `create-position(sbtc-contract, amount, lock-period-blocks)` - Create a new staking position
- `claim-rewards(sbtc-contract)` - Claim accumulated rewards
- `close-position(sbtc-contract)` - Close position and withdraw stake

#### Administrative Functions

- `update-base-rewards-rate(new-rate)` - Update the base APR (owner only)
- `update-sbtc-contract(new-contract)` - Update the sBTC token contract (owner only)
- `pause-protocol(pause)` - Pause/unpause the protocol (owner only)
- `activate-emergency-mode()` - Activate emergency mode (owner only)
- `emergency-withdraw(sbtc-contract, recipient, amount)` - Emergency withdrawal (owner only)

### Read-Only Functions

- `get-user-position(user)` - Get user's staking position details
- `get-user-statistics(user)` - Get user's lifetime statistics
- `get-protocol-info()` - Get protocol metrics and configuration
- `get-available-rewards(user)` - Calculate available rewards for user
- `is-position-unlocked(user)` - Check if user's position is unlocked

## 🧮 Reward Calculation

The protocol uses a sophisticated reward calculation system:

```clarity
Base Rewards = (Stake Amount × Base APR × Blocks Elapsed) / (Precision Factor × Blocks Per Year)
Lock Bonus = Base Rewards × Lock Multiplier / Precision Factor
Total Rewards = Base Rewards + Lock Bonus
```

### Example Calculation

For a 1 sBTC stake with 5% base APR and 1-year lock (5% bonus):

- Base Annual Reward: 0.05 sBTC
- Lock Bonus: 0.0025 sBTC (5% of base)
- Total Annual Reward: 0.0525 sBTC (5.25% APR)

## 🔒 Security Considerations

### Access Controls

- **Contract Owner**: Can modify protocol parameters and handle emergencies
- **Users**: Can only manage their own positions
- **Emergency Mode**: Restricts protocol functionality to emergency withdrawals only

### Input Validation

- Amount validation (minimum stake requirements)
- Lock period validation (within allowed range)
- Contract validation (sBTC token authenticity)
- Principal validation (standard address format)

### Overflow Protection

- Safe arithmetic operations with bounds checking
- Sanity checks on reward calculations
- Maximum reward caps to prevent exploits

## 🚨 Emergency Procedures

### Protocol Pause

The protocol can be paused by the contract owner to prevent new interactions while preserving existing positions.

### Emergency Mode

In critical situations, emergency mode can be activated, which:

- Pauses the protocol
- Enables emergency withdrawals by the owner
- Restricts all other protocol functions

## 📊 Testing

The protocol includes comprehensive tests covering:

- Position creation and management
- Reward calculations and claiming
- Lock period enforcement
- Administrative functions
- Error conditions and edge cases

```bash
# Run all tests
npm test

# Run specific test file
npx vitest tests/nexus-vault.test.ts

# Run with coverage
npm run test:coverage
```

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

### Development Setup

1. Fork the repository
2. Create a feature branch: `git checkout -b feature-name`
3. Make your changes and add tests
4. Ensure tests pass: `npm test`
5. Submit a pull request

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🗺 Roadmap

### Phase 1 (Current)

- [x] Core staking functionality
- [x] Time-locked deposits
- [x] Dynamic reward system
- [x] Basic administration

### Phase 2

- [ ] Multi-asset support
- [ ] Governance token integration
- [ ] Advanced analytics dashboard
- [ ] Mobile SDK

### Phase 3

- [ ] Cross-chain bridging
- [ ] Automated yield strategies
- [ ] Insurance integration
- [ ] DAO governance
