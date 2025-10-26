// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Script} from "lib/forge-std/src/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {AddConsumer} from "./Interactions.s.sol";

contract DeployRaffle is Script {
    function run() public {
        deployRaffle();
    }

    function deployRaffle() public returns (Raffle raffle) {
        AddConsumer consumer = new AddConsumer(); // init!
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        vm.startBroadcast(config.account);
        raffle = new Raffle(
            config.entranceFee,
            config.vrfCoordinator,
            config.gasLane,
            config.subscriptionId,
            config.callbackGasLimit,
            config.maxAmountOfPlayers
        );
        vm.stopBroadcast();
        if (block.chainid == 31337) {
            consumer.addConsumerByConfig(address(raffle));
        }
    }
}
