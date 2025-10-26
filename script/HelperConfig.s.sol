// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Script} from "lib/forge-std/src/Script.sol";
import {ReentrancyGuard} from "lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import {MockToken} from "../test/mocks/TokenToFundVRF.sol";
import {
    VRFCoordinatorV2Mock
} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2Mock.sol";

abstract contract CodeConstants {
    VRFCoordinatorV2Mock vrfCoordinator;
    MockToken linkToken;

    error HelperConfig_InVaildChainId(uint256 chainId);

    uint96 public constant MOCK_BASE_FEE = 0.25 * 10 ** 18; // 0.25 LINK
    uint96 public constant MOCK_GAS_PRICE = 1e9; // 1 gwei
    int256 public constant MOCK_WEI_PER_UNIT_LINK = 4e15; // 1 LINK
    uint256 public constant LINK_TOKEN_INITIAL_SUPPLY = 1000 * 1e18;
    uint64 public constant VRF_COORDINATOR_TOKEN_FUND = 12;
    uint256 public constant ARBITRUM_MAINNET_CHAINID = 42161;
    uint256 public constant ARBITRUM_SEPOLIA_CHAINID = 421614;
    uint256 public constant ETH_SEPOLIA_CHAINID = 11155111;
    uint256 public constant ETH_LOCALHOST_CHAINID = 31337;
}

contract HelperConfig is Script, CodeConstants, ReentrancyGuard {
    struct NetworkConfig {
        address vrfCoordinator;
        bytes32 gasLane;
        uint256 subscriptionId;
        uint32 callbackGasLimit;
        address link;
        uint256 entranceFee;
        uint256 account; // this only for mock and testing
        uint8 maxAmountOfPlayers;
    }

    uint256 public constant DEFAULT_ANVIL_PRIVATE_KEY =
        0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

    NetworkConfig public activeNetworkCnfig;

    constructor() {
        if (block.chainid == ETH_SEPOLIA_CHAINID) {
            activeNetworkCnfig = getSepoliaEthConfig();
        } else if (block.chainid == ARBITRUM_SEPOLIA_CHAINID) {
            activeNetworkCnfig = getArbitrumSepoliaConfig();
        } else if (block.chainid == ETH_LOCALHOST_CHAINID) {
            activeNetworkCnfig = getOrCreateAnvilConfig();
        }
    }

    function getConfig() public returns (NetworkConfig memory) {
        return getConfigByChainId(block.chainid);
    }

    function getConfigByChainId(uint256 _chainid) public returns (NetworkConfig memory) {
        if (_chainid == ETH_SEPOLIA_CHAINID) {
            return activeNetworkCnfig = getSepoliaEthConfig();
        } else if (_chainid == ARBITRUM_SEPOLIA_CHAINID) {
            return activeNetworkCnfig = getArbitrumSepoliaConfig();
        } else if (_chainid == ETH_LOCALHOST_CHAINID) {
            return activeNetworkCnfig = getOrCreateAnvilConfig();
        } else {
            revert HelperConfig_InVaildChainId(_chainid);
        }
    }

    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({
            vrfCoordinator: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
            gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            subscriptionId: 64557647921297966695533544969556792079690566266549545196356203862151028989619,
            callbackGasLimit: 500000,
            link: 0x779877A7B0D9E8603169DdbD7836e478b4624789,
            entranceFee: 0.01 ether,
            account: 123, // this onchain so this not mock
            maxAmountOfPlayers: 10
        });
    }

    function getArbitrumSepoliaConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({
            vrfCoordinator: 0x5CE8D5A2BC84beb22a398CCA51996F7930313D61,
            gasLane: 0x1770bdc7eec7771f7ba4ffd640f34260d7f095b79c92d34a5b2551d6f6cfd2be,
            subscriptionId: 85858154034126482486316423090340180180418015141665039564292128215341491466987,
            callbackGasLimit: 500000,
            link: 0xb1D4538B4571d411F07960EF2838Ce337FE1E80E,
            entranceFee: 0.01 ether,
            account: 124,
            maxAmountOfPlayers: 10
        });
    }

    function getOrCreateAnvilConfig() public nonReentrant returns (NetworkConfig memory) {
        vm.startBroadcast();
        vrfCoordinator = new VRFCoordinatorV2Mock(MOCK_BASE_FEE, MOCK_GAS_PRICE);
        linkToken = new MockToken(LINK_TOKEN_INITIAL_SUPPLY);
        uint64 subsId = vrfCoordinator.createSubscription();
        vrfCoordinator.fundSubscription(subsId, VRF_COORDINATOR_TOKEN_FUND);
        vm.stopBroadcast();
        return NetworkConfig({
            vrfCoordinator: address(vrfCoordinator),
            gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            subscriptionId: uint64(subsId),
            callbackGasLimit: 500000,
            link: address(linkToken),
            entranceFee: 0.01 ether,
            account: DEFAULT_ANVIL_PRIVATE_KEY,
            maxAmountOfPlayers: 10
        });
    }
}
