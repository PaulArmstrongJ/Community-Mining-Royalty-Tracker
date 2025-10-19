A transparent smart contract system that ensures mining communities receive their promised royalties automatically and verifiably.

## 🎯 Problem Solved

Local communities often don't receive promised mining royalties due to lack of transparency and accountability in traditional payment systems.

## ✨ Key Features

- 🔍 **Transparent Royalty Calculations** - All royalty percentages and calculations are public and verifiable
- 🏦 **Fixed Wallet Allocation** - Communities have designated wallets that automatically receive payments
- 📊 **Public Payout History** - Complete history of all royalty distributions is permanently recorded
- ⚡ **Automatic Distribution** - Royalties are distributed immediately when mining production is logged

## 🚀 Quick Start

### Prerequisites
- Clarinet CLI installed
- STX tokens for testing

### Setup
```bash
clarinet console
```

### 📝 Usage Instructions

#### 1. Register a Community 👥
```clarity
(contract-call? .Community-Mining-Royalty-Tracker register-community "Village Alpha" 'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7 u10)
```

#### 2. Log Mining Production ⛏️
```clarity
(contract-call? .Community-Mining-Royalty-Tracker log-mining-production "Mine Site A" u1000000 u1)
```

#### 3. Fund the Contract 💰
```clarity
(contract-call? .Community-Mining-Royalty-Tracker fund-contract)
```

### 🔍 Query Functions

#### Get Community Information
```clarity
(contract-call? .Community-Mining-Royalty-Tracker get-community u1)
```

#### View Mining Operation
```clarity
(contract-call? .Community-Mining-Royalty-Tracker get-mining-operation u1)
```

#### Check Payout History
```clarity
(contract-call? .Community-Mining-Royalty-Tracker get-community-payout u1 u1)
```

#### Get Contract Balance
```clarity
(contract-call? .Community-Mining-Royalty-Tracker get-contract-balance)
```

## 🏗️ Contract Functions

### Public Functions

| Function | Description |
|----------|-------------|
| `register-community` | Register a new community with royalty percentage |
| `log-mining-production` | Record mining production and trigger royalty distribution |
| `fund-contract` | Add STX tokens to the contract for royalty payments |
| `deactivate-community` | Disable a community (owner only) |
| `update-royalty-percentage` | Modify community royalty rate (owner only) |
| `update-community-wallet` | Update a community's wallet address (owner only) |

### Read-Only Functions

| Function | Description |
|----------|-------------|
| `get-community` | Retrieve community details |
| `get-mining-operation` | Get mining operation information |
| `get-community-payout` | View specific payout details |
| `get-contract-balance` | Check available contract funds |
| `calculate-royalty` | Preview royalty calculation |

## 🧪 Testing

Run the test suite:
```bash
npm test
```

Run tests with coverage:
```bash
npm run test:report
```

## 📊 Contract Architecture

The contract maintains three main data structures:
- **Communities**: Registered communities with their wallet addresses and royalty percentages
- **Mining Operations**: Production logs with associated royalty calculations
- **Payouts**: Historical record of all royalty distributions

## 🔒 Security Features

- Owner-only administrative functions
- Input validation on all parameters  
- Balance checks before transfers
- Community activation status controls

## 📈 Royalty Calculation

Royalties are calculated as: `(Production Value × Royalty Percentage) / 100`

Example: $100,000 production × 10% royalty = $10,000 to community

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch
3. Add tests for new functionality
4. Run `clarinet check` to validate syntax
5. Submit a pull request

## 📄 License

MIT License - see LICENSE file for details
