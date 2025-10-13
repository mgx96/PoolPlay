FLOW_SEPOLIA_EVM=https://testnet.evm.nodes.onflow.org
PRIVATE_KEY=05563997b1cf584d32497cb33bc43167a324baaa5fe05d089e1d49b801a7b3bd
WALLET_ADDRESS=0x08282fD83115086701a0D165ADB89271B5468AbB
FLOW_VERFIER_URL=https://evm-testnet.flowscan.io/api
DEPLOY_CONTRACT_ADDRESS=0x054f2A9e9D61BA49aa1a5102350f65fDa7FfE4fD
flow_evm:
	forge script script/Counter.s.sol:CounterScript --rpc-url ${FLOW_SEPOLIA_EVM} --private-key ${PRIVATE_KEY} --broadcast --legacy


balance:
	cast balance --ether --rpc-url ${FLOW_SEPOLIA_EVM} 0x08282fD83115086701a0D165ADB89271B5468AbB

flowERC20:
	cast call 0x054f2A9e9D61BA49aa1a5102350f65fDa7FfE4fD "balanceOf(address)" ${WALLET_ADDRESS} --rpc-url ${FLOW_SEPOLIA_EVM}

verifyFlewEvm:
	forge verify-contract --rpc-url ${FLOW_SEPOLIA_EVM} --verifier blockscout --verifier-url ${FLOW_VERFIER_URL} ${DEPLOY_CONTRACT_ADDRESS} src/Counter.sol:Counter