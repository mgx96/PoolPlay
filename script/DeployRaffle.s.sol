// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {CreateSubscription} from "./Interactions.s.sol";

contract DeployRaffle is Script {
    function run() external {
        vm.startBroadcast();

        vm.stopBroadcast();
    }

    function deployRaffle() external returns (Raffle, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();

        // local -> deploy mocks, get local config
        // sepolia -> get sepolia config
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        if (config.subscriptionId == 0) {
            CreateSubscription createSubscription = new CreateSubscription();
            (config.subscriptionId, config.vrfCoordinator) =
                createSubscription.createSubscription(config.vrfCoordinator);
        }
        vm.startBroadcast();
        Raffle raffle = new Raffle(
            config.entranceFee,
            config.vrfCoordinator,
            config.gasLane,
            config.subscriptionId,
            config.callbackGasLimit,
            config.maxAmountOfPlayers
        );
        vm.stopBroadcast();
        return (raffle, helperConfig);
    }
}
