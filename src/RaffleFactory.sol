//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Raffle} from "./Raffle.sol";

contract RaffleFactory {
    error RaffleFactory__InvalidPool();

    address[] public deployedRaffles;

    event RaffleCreated(address raffleAddress, uint8 poolType, uint256 entranceFee);

    function createPool(
        uint8 poolType,
        uint256 entranceFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 gasLane,
        uint256 subscriptionId,
        uint32 callbackGasLimit
    ) external returns (address) {

        // Validate pool size
        if (poolType != 5 && poolType != 10 && poolType != 25) {
            revert RaffleFactory__InvalidPool();
        }

        // Deploy new raffle
        Raffle raffle = new Raffle(
            entranceFee,
            interval,
            vrfCoordinator,
            gasLane,
            subscriptionId,
            callbackGasLimit,
            poolType
        );

        deployedRaffles.push(address(raffle));
        emit RaffleCreated(address(raffle), poolType, entranceFee);

        return address(raffle);
    }
}
