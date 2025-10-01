// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/Raffle.sol"; // Adjust this import depending on your folder structure

contract RaffleTest is Test {
    Raffle raffle;

    // Dummy VRF constructor params for testing
    uint256 constant ENTRANCE_FEE = 0.1 ether;
    uint256 constant INTERVAL = 30;
    address constant VRF_COORDINATOR = address(0x123);
    bytes32 constant GAS_LANE = bytes32(0);
    uint256 constant SUBSCRIPTION_ID = 1;
    uint32 constant CALLBACK_GAS_LIMIT = 500000;
    uint8 constant MAX_PLAYERS = 5;

    function setUp() public {
        raffle = new Raffle(
            ENTRANCE_FEE,
            INTERVAL,
            VRF_COORDINATOR,
            GAS_LANE,
            SUBSCRIPTION_ID,
            CALLBACK_GAS_LIMIT,
            MAX_PLAYERS
        );
    }

    function testDeploys() public {
        assertTrue(address(raffle) != address(0));
    }
}
