// Layout of Contract:
// license
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// internal & private view & pure functions
// external & public view & pure functions

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

/**
 * @title Raffle Contract
 * @author Malek Sharabi
 * @notice This contract implements a raffle system where users can enter by paying a fee, and a random winner is selected at regular intervals.
 * @dev The contract uses Chainlink VRFv2.5 for randomness and Chainlink Keepers for automation.
 */
contract Raffle is VRFConsumerBaseV2Plus {
    /* Errors */
    error Raffle__NotEnoughETHEntered();
    error Raffle__TransferFailed();
    error Raffle__RaffleNotOpen();
    error Raffle__RaffleIsFull();
    error Raffle__upkeepNotNeeded(
        uint256 balance,
        uint256 playersLength,
        uint256 raffleState
    );

    /*Type Declarations */
    enum RaffleState {
        OPEN,
        CALCULATING
    }

    /* State Variables */
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;
    uint256 private immutable i_entranceFee;
    uint256 private immutable i_interval;
    bytes32 private immutable i_keyHash;
    uint256 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
    address payable[] private s_players;
    uint8 private s_maxAmountOfPlayers;
    uint256 private s_lastTimeStamp;
    address private s_recentWinner;
    RaffleState private s_raffleState;

    /* Events */
    event RaffleEntered(address indexed player);
    event WaitingForMorePlayers(uint256 currentPlayers, uint8 maxPlayers);
    event WinnerPicked(address indexed winner);

    constructor(
        uint256 entranceFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 gasLane,
        uint256 subscriptionId,
        uint32 callbackGasLimit,
        uint8 maxAmountOfPlayers
    ) VRFConsumerBaseV2Plus(vrfCoordinator) {
        i_entranceFee = entranceFee;
        // @dev The duration of the lottery in seconds
        i_interval = interval;
        i_keyHash = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        s_raffleState = RaffleState.OPEN;
        s_maxAmountOfPlayers = maxAmountOfPlayers;
    }

    function enterRaffle() external payable {
        // require(msg.value >= i_entranceFee, "You need to send more ETH to cover the entrance fee");
        if (msg.value < i_entranceFee) {
            // this is more gas efficient than require
            revert Raffle__NotEnoughETHEntered();
        }
        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__RaffleNotOpen();
        }
        if (s_players.length >= s_maxAmountOfPlayers) {
            revert Raffle__RaffleIsFull();
        }
        s_players.push(payable(msg.sender));
        emit RaffleEntered(msg.sender);

        if (s_players.length < s_maxAmountOfPlayers) {
            emit WaitingForMorePlayers(s_players.length, s_maxAmountOfPlayers);
        }
    }

    /**
     * @dev This is the function that the Chainlink nodes will call to see if the lottery is ready to have a winner picked:
     * The following should be true in order for upkeepNeeded to be true:
     * 1. The lottery is in an "open" state.
     * 2. The contract has ETH.
     * 3. Implicitly, your subscription is funded with LINK.
     * 4. The required amount of players has been reached.
     * @param - not used in this implementation.
     * @return upkeepNeeded - true if it's time to restart the lottery.
     * @return - ignored
     */
    function checkUpkeep(
        bytes memory
    ) public view returns (bool upkeepNeeded, bytes memory) {
        bool isOpen = s_raffleState == RaffleState.OPEN;
        bool hasBalance = address(this).balance > 0;
        bool hasPlayers = s_players.length > 0;
        bool requiredAmountOfPlayers = s_players.length == s_maxAmountOfPlayers;
        upkeepNeeded =
            isOpen &&
            hasBalance &&
            hasPlayers &&
            requiredAmountOfPlayers;
        return (upkeepNeeded, "");
    }

    function performUpkeep(bytes calldata) external {
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Raffle__upkeepNotNeeded(
                address(this).balance,
                s_players.length,
                uint256(s_raffleState)
            );
        }
        s_raffleState = RaffleState.CALCULATING;
        VRFV2PlusClient.RandomWordsRequest memory request = VRFV2PlusClient
            .RandomWordsRequest({
                keyHash: i_keyHash,
                subId: i_subscriptionId,
                requestConfirmations: REQUEST_CONFIRMATIONS,
                callbackGasLimit: i_callbackGasLimit,
                numWords: NUM_WORDS,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            });
        uint256 requestId = s_vrfCoordinator.requestRandomWords(request);
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] calldata randomWords
    ) internal override {
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[indexOfWinner];
        s_recentWinner = recentWinner;

        s_raffleState = RaffleState.OPEN;
        s_players = new address payable[](0);
        s_lastTimeStamp = block.timestamp;

        (bool success, ) = recentWinner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle__TransferFailed();
        }
        emit WinnerPicked(s_recentWinner);
    }

    function getEntranceFee() public view returns (uint256) {
        return i_entranceFee;
    }

    function getInterval() public view returns (uint256) {
        return i_interval;
    }

    function getMaxPlayers() public view returns (uint8) {
        return s_maxAmountOfPlayers;
    }

    function getPlayersCount() public view returns (uint256) {
        return s_players.length;
    }

    function getRaffleState() public view returns (RaffleState) {
        return s_raffleState;
    }
}
