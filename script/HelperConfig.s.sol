// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import "forge-std/Script.sol";
import {VRFCoordinatorV2_5Mock} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

abstract contract CodeConstants {
    uint96 public constant MOCK_BASE_FEE = 0.25 * 10 ** 18; // 0.25 LINK
    uint96 public constant MOCK_GAS_PRICE = 1e9; // 1 gwei
    int256 public constant MOCK_WEI_PER_UNIT_LINK = 4e15; // 1 LINK
    uint256 public constant ARBITRUM_MAINNET_CHAINID = 42161;
    uint256 public constant ARBITRUM_SEPOLIA_CHAINID = 11155111;
    uint256 public constant ETH_LOCALHOST_CHAINID = 31337;
}

contract HelperConfig is CodeConstants, Script {
    error HelperConfig__InvalidChainId();
    struct NetworkConfig {
        uint256 entranceFee;
        address vrfCoordinator;
        bytes32 gasLane;
        uint256 subscriptionId;
        uint32 callbackGasLimit;
        uint8 maxAmountOfPlayers;
    }
    NetworkConfig public localNetworkConfig;
    mapping(uint256 chainId => NetworkConfig) public networkConfigs;

    constructor() {
        networkConfigs[ARBITRUM_SEPOLIA_CHAINID] = getArbitrumSepoliaConfig();
        // networkConfigs[ARBITRUM_MAINNET_CHAINID] = getArbitrumMainnetConfig();
        // networkConfigs[ETH_LOCALHOST_CHAINID] = getOrCreateAnvilEthConfig();
    }

    function getConfig() public returns (NetworkConfig memory) {
        return getConfigByChainId(block.chainid);
    }

    function getConfigByChainId(
        uint256 chainId
    ) public returns (NetworkConfig memory) {
        if (networkConfigs[chainId].vrfCoordinator != address(0)) {
            return networkConfigs[chainId];
        } else if (chainId == ETH_LOCALHOST_CHAINID) {
            // return localhost config
            return getOrCreateAnvilEthConfig();
        } else {
            revert HelperConfig__InvalidChainId();
        }
    }

    function getArbitrumSepoliaConfig()
        public
        pure
        returns (NetworkConfig memory)
    {
        return
            NetworkConfig({
                entranceFee: 0.01 ether, // 1e16
                vrfCoordinator: 0x50d47e4142598E3411aA864e08a44284e471AC6f,
                gasLane: 0x54d8e6f2c1e1fdd4f8f7c5144a7be3a3f0a2b3b4c6d5e6f7a8b9c0d1e2f3a4b5,
                subscriptionId: 0, // update this with your subscription id
                callbackGasLimit: 5000000,
                maxAmountOfPlayers: 10
            });
    }

    function getArbitrumMainnetConfig()
        public
        pure
        returns (NetworkConfig memory)
    {
        return
            NetworkConfig({
                entranceFee: 0.01 ether, // 1e16
                vrfCoordinator: 0x41034678D6C633D8a95c75e1138A360a28bA15d1,
                gasLane: 0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef,
                subscriptionId: 0, // update this with your subscription id
                callbackGasLimit: 5000000,
                maxAmountOfPlayers: 10
            });
    }

    function getOrCreateAnvilEthConfig()
        public
        returns (NetworkConfig memory anvilNetworkConfig)
    {
        // Check to see if we set an active network localNetworkConfig
        if (localNetworkConfig.vrfCoordinator != address(0)) {
            return localNetworkConfig;
        }
        vm.startBroadcast();
        VRFCoordinatorV2_5Mock vrfCoordinatorMock = new VRFCoordinatorV2_5Mock(
            MOCK_BASE_FEE,
            MOCK_GAS_PRICE,
            MOCK_WEI_PER_UNIT_LINK
        ); //uint96 _baseFee, uint96 _gasPrice, int256 _weiPerUnitLink
        vm.stopBroadcast();

        localNetworkConfig = NetworkConfig({
            entranceFee: 0.01 ether,
            vrfCoordinator: address(vrfCoordinatorMock),
            gasLane: bytes32(0), // doesn't matter
            subscriptionId: 0, // might have to update this
            callbackGasLimit: 500,
            maxAmountOfPlayers: 10
        });
        return localNetworkConfig;
    }
}
