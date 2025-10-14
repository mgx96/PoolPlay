
SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/QlXFO2edkPcV7HHJcx89G
ARBITRUM_SEPOLIA=https://arb-sepolia.g.alchemy.com/v2/QlXFO2edkPcV7HHJcx89G
ARBITRUM_MAINNET=https://arb-mainnet.g.alchemy.com/v2/QlXFO2edkPcV7HHJcx89G
ANVIL_RPC_URL=http://127.0.0.1:8545

# Private key / account
ANVIL_PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80   # or set as env variable
ACCOUNT=keyStore   # for Anvil / local default signer index

# Forge deploy script
FORGE_SCRIPT=forge script script/DeployRaffle.s.sol:DeployRaffle

# Pre-deployed contracts (if any)
ARB_SEPOLIA_CONTRACT=0x1473A50d9868fBC49eD6Dcc5717b9DFb4c9EA034
ETH_SEPOLIA_CONTRACT=0xc025C97BE940c53080D6fA437C684334fC0261D5

# Targets
ethSepolia:
	${FORGE_SCRIPT} --rpc-url ${SEPOLIA_RPC_URL} --account ${ACCOUNT} --broadcast --verify -vvv

arbSepolia:
	${FORGE_SCRIPT} --rpc-url ${ARBITRUM_SEPOLIA} --account ${ACCOUNT} --broadcast --verify -vvv

arbMainnet:
	${FORGE_SCRIPT} --rpc-url ${ARBITRUM_MAINNET} --account ${ACCOUNT} --broadcast --verify -vvv

anvil:
	${FORGE_SCRIPT} --rpc-url ${ANVIL_RPC_URL} --private-key ${ANVIL_PRIVATE_KEY} --broadcast -vvvvg