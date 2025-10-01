# PlayPool

PlayPool is an experimental decentralized lottery protocol built on Layer 2 networks. It introduces risk-adjusted prize pools with fixed participant sizes, using verifiable on-chain randomness to determine winners in a fully transparent and non-custodial manner.

The goal of the project is to explore trusted randomness mechanics and decentralized prize distribution on-chain, while providing a foundation that could evolve into a production-ready protocol.

---

## Key Features

- Tiered lottery pools with fixed participant sizes (5, 10, 25)
- Higher entry fees for smaller pools to balance odds and rewards
- Winner-takes-all distribution model
- Crypto-native architecture with no centralized custody
- On-chain verifiable randomness (Chainlink VRF or equivalent)
- Fully permissionless smart contract interactions

---

## Architecture

| Component | Description |
|-----------|-------------|
| Smart Contracts | Core pool logic and reward distribution |
| Randomness Provider | Chainlink VRF |
| Frontend | React.js / TypeScript interface for pool creation and participation |
| Tooling | Foundry for development, testing, and deployments |

---

## Smart Contract Design

Contracts are structured around a minimal pool abstraction:

- Each pool is instantiated with a fixed participant cap
- Users join by sending the required entry amount
- Once the pool reaches capacity, the contract requests randomness
- The winner is selected based on modulo indexing
- Rewards are distributed automatically

Pools are deterministic and operate without owner intervention once deployed.

---

## Prize Pool Mechanics

| Pool Size | Example Entry Amount | Win Chance |
|-----------|---------------------|------------|
| 5         | High (e.g. premium tier) | 20% |
| 10        | Moderate | 10% |
| 25        | Low | 4% |

Entry amounts are configurable and determined at pool deployment. Payout models may be extended in future versions (e.g. weighted distribution or multiple winners).

---

## Randomness & Fairness

Randomness is sourced via Chainlink VRF. The random value is reduced to a valid participant index using the modulo operator:

winnerIndex = randomValue % playerCount


This guarantees a uniform distribution across all participants while remaining deterministic and publicly verifiable.

---

## Legal Notice

This repository is an experimental research project and not intended for production use. There are no guarantees regarding security or regulatory compliance. Any deployment or use of the code is done at the user's own risk and responsibility.

---

## Tech Stack

| Layer | Technology |
|-------|------------|
| Smart Contracts | Solidity |
| Development Framework | Foundry |
| Frontend | Next.js + TypeScript |
| Networks | Polygon or Arbitrum (TBD) |

---

## Installation

```bash
git clone https://github.com/your-org/playpool.git
cd playpool
```

## Install smart contract dependencies

```bash
forge install
```

## Install frontend dependencies

```bash
cd frontend
npm install
```

---

## Running Locally

## Local blockchain

```bash
anvil
```

## Deploy contracts

```bash
forge script script/Deploy.s.sol --broadcast
```

## Start frontend

```bash
cd frontend
npm run dev
```

---

## Deployment

Deployment scripts are provided under /script. Network configuration is located in foundry.toml.
Example:

```bash
forge script script/Deploy.s.sol --rpc-url <NETWORK_RPC> --broadcast
```

---

## Contributing

PlayPool is an open research project. Contributions via pull requests are welcome. For larger discussions, please open an issue to coordinate design proposals.

## License

MIT
