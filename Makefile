# Makefile for deploying Solidity contracts with Foundry

# CONFIG
CONTRACT=MyContract
ETH_SEPOLIA_RPC=https://eth-sepolia.g.alchemy.com/v2/YOUR_KEY
ARB_SEPOLIA_RPC=https://arb-sepolia.g.alchemy.com/v2/YOUR_KEY
ARB_MAINNET_RPC=https://arb-mainnet.g.alchemy.com/v2/YOUR_KEY
ANVIL_RPC=http://127.0.0.1:8545

# DEPLOY COMMANDS
deploy-eth-sepolia:
	forge script script/DeployRaffle.s.sol:DeployRaffle --rpc-url $(ETH_SEPOLIA_RPC) --broadcast --private-key $$ETH_SEPOLIA_PRIVATE_KEY

deploy-arb-sepolia:
	forge script script/DeployRaffle.s.sol:DeployRaffle --rpc-url $(ARB_SEPOLIA_RPC) --broadcast --private-key $$ARB_SEPOLIA_PRIVATE_KEY

deploy-arb-mainnet:
	forge script script/DeployRaffle.s.sol:DeployRaffle --rpc-url $(ARB_MAINNET_RPC) --broadcast --private-key $$ARB_MAINNET_PRIVATE_KEY

anvil:
	forge script script/DeployRaffle.s.sol:DeployRaffle --rpc-url $(ANVIL_RPC) --broadcast --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80