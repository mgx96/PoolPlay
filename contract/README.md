### Project Description
Rupee-Coin is a decentralized, INR-pegged stablecoin forked from MakerDAO's DAI system. Users deposit exogenous collateral (wETH, wBTC) to mint Rupee Coin while maintaining a health factor; supports withdrawals, burns for undercollateralized positions, and liquidations with rewards. Leverages Chainlink oracles for ETH/BTC-INR prices, with an aggregator interface for robust feeds. Deployed on Sepolia testnet for algorithmic stability in Indian markets.

### README.md

# Rupee-Coin: INR-Pegged Decentralized Stablecoin

## Overview
Rupee-Coin enables users to mint a stablecoin pegged to the Indian Rupee by depositing collateral like wETH or wBTC. Built on Ethereum (Sepolia testnet), it ensures stability through overcollateralization, health factor checks, and liquidation mechanics.

## Differences from Original MakerDAO (DAI)
- **Peg Currency**: Pegged to INR instead of USD, targeting Indian users and markets.
- **Collateral Types**: Limited to wETH and wBTC (exogenous only), vs. MakerDAO's multi-collateral including real-world assets.
- **Oracle System**: Uses IPriceFeedsAggregator interface for multi-source aggregation (e.g., Chainlink + others), reducing single-point failure vs. Maker's ilk-specific medianizers.
- **Auction/Liquidation**: Simplified liquidation with direct rewards; no full Dutch auctions like Maker's Clipper, focusing on efficiency for smaller scale.
- **Deployment**: Testnet-focused with custom engine contract, vs. Maker's mainnet production with governance (MKR token).

## What Makes It Powerful After Implementing the Original (OG) Contracts
Forking MakerDAO's DSS (e.g., clip.sol for auctions) adds:
- **Robust Liquidations**: OG Clipper enables efficient collateral auctions, preventing system debt buildup.
- **Enhanced Stability**: Combined with aggregator oracles, it mitigates price manipulation risks, improving reliability over basic feeds.
- **Scalability**: Modular design allows easy INR-specific tweaks, like regional oracles, making it more resilient and adaptable for emerging markets vs. standard forks.
- **Gas Efficiency**: Cached values (e.g., chost) reduce costs in auctions, powering high-volume operations.

For setup: Clone repo, deploy via Foundry/Hardhat. Test on Sepolia. See contracts in /src for details.
