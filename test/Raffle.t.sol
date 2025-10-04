// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {Raffle} from "../src/Raffle.sol"; // Adjust this import depending on your folder structure
import {RaffleFactory} from "../src/RaffleFactory.sol";
import {DeployRaffle} from "../script/DeployRaffle.s.sol";
import {HelperConfig, CodeConstants} from "../script/HelperConfig.s.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {MockToken} from "./mocks/TokenToFundVRF.sol";

contract RaffleTest is Test, CodeConstants {
    Raffle raffle;
    RaffleFactory factory;
    HelperConfig public helperConfig;

    // Dummy VRF constructor params for testing
    uint256 ENTRANCE_FEE = 0.1 ether;
    address VRF_COORDINATOR;
    bytes32 GAS_LANE = bytes32(0);
    uint256 public subId;
    uint32 CALLBACK_GAS_LIMIT = 500000;
    uint8 MAX_PLAYERS;

    //mock player
    address public PLAYER = makeAddr("player1");
    uint256 public STARTING_BALANCE = 10 ether;

    /* Events */
    event RaffleEntered(address indexed player);
    event WaitingForMorePlayers(uint256 currentPlayers, uint8 maxPlayers);
    event WinnerPicked(address indexed winner);

    function setUp() public {
        DeployRaffle deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.deployRaffle();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        ENTRANCE_FEE = config.entranceFee;
        VRF_COORDINATOR = config.vrfCoordinator;
        GAS_LANE = config.gasLane;
        CALLBACK_GAS_LIMIT = config.callbackGasLimit;
        MAX_PLAYERS = config.maxAmountOfPlayers;
        subId = config.subscriptionId;

        vm.startPrank(address(this)); // or use config.account if needed
        VRFCoordinatorV2_5Mock(VRF_COORDINATOR).fundSubscription(subId, 10 ether);
        vm.stopPrank();
        vm.deal(PLAYER, STARTING_BALANCE);
    }

    modifier raffleEntered() {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: ENTRANCE_FEE}();
        _;
    }

    modifier maxPlayersEntered() {
        // Fill up the raffle with 5 players
        for (uint160 i = 1; i <= 5; i++) {
            address player = makeAddr(string.concat("player", vm.toString(i)));
            vm.deal(player, 1 ether);
            vm.prank(player);
            raffle.enterRaffle{value: ENTRANCE_FEE}();
        }
        _;
    }

    function testDeploys() public view {
        assertTrue(address(raffle) != address(0));
    }

    //test_<unitUnderTest>_<stateOrCondition>_<expectedOutcome/Behaviour>

    /*//////////////////////////////////////////////////////////////
                           ENTER RAFFLE TESTS
    //////////////////////////////////////////////////////////////*/
    function test_enterRaffle_reverts_ifNotEnoughFee() public {
        uint256 insufficienteFee = ENTRANCE_FEE - 0.005 ether;

        vm.prank(PLAYER);
        vm.expectRevert(Raffle.Raffle__NotEnoughETHEntered.selector);
        raffle.enterRaffle{value: insufficienteFee}();
    }

    function test_enterRaffle_reverts_whenRaffleIsNotOpen() public maxPlayersEntered {
        // Call performUpkeep to simulate Chainlink Keepers
        raffle.performUpkeep(""); //CALCULATING
        assertEq(uint256(raffle.getRaffleState()), uint256(Raffle.RaffleState.CALCULATING));

        vm.prank(PLAYER);
        vm.expectRevert(Raffle.Raffle__RaffleNotOpen.selector);
        raffle.enterRaffle{value: ENTRANCE_FEE}();
    }

    function test_enterRaffle_reverts_IfRaffleIsFull() public maxPlayersEntered {
        //raffle should be full (5/5 players)
        assertEq(raffle.getPlayersCount(), 5);

        // Try a 6th player
        vm.prank(PLAYER);
        vm.expectRevert(Raffle.Raffle__RaffleIsFull.selector);
        raffle.enterRaffle{value: ENTRANCE_FEE}();
    }

    function test_enterRaffle_recordsPlayerAndEmitEvent() public {
        vm.prank(PLAYER);
        vm.expectEmit(true, false, false, false, address(raffle));
        emit RaffleEntered(PLAYER);
        raffle.enterRaffle{value: ENTRANCE_FEE}();
        assertEq(raffle.getPlayersCount(), 1);
    }

    function test_enterRaffle_emits_waitingForMorePlayers() public raffleEntered {
        vm.expectEmit(false, false, false, false, address(raffle));
        emit WaitingForMorePlayers(raffle.getPlayersCount(), MAX_PLAYERS);
        raffle.enterRaffle{value: ENTRANCE_FEE}();
    }

    /*//////////////////////////////////////////////////////////////
                          CHECKUPKEEP TESTS
    //////////////////////////////////////////////////////////////*/
    function test_checkUpkeep_returnsFalse_ifRaffleNotOpen() public maxPlayersEntered {
        // move to CALCULATING
        raffle.performUpkeep("");

        (bool upkeepNeeded,) = raffle.checkUpkeep("");
        assertFalse(upkeepNeeded);
    }

    function test_checkUpkeep_returnsFalse_ifNoBalance() public view {
        // just created raffle, no ETH balance
        (bool upkeepNeeded,) = raffle.checkUpkeep("");
        assertFalse(upkeepNeeded);
    }

    function test_checkUpkeep_returnsFalse_ifNotEnoughPlayers() public view {
        // no players yet
        (bool upkeepNeeded,) = raffle.checkUpkeep("");
        assertFalse(upkeepNeeded);
    }

    function test_checkUpkeep_returnsTrue_whenAllConditionsMet() public maxPlayersEntered {
        (bool upkeepNeeded,) = raffle.checkUpkeep("");
        assertTrue(upkeepNeeded);
    }

    /*//////////////////////////////////////////////////////////////
                          PERFORMUPKEEP TESTS
    //////////////////////////////////////////////////////////////*/
    function test_performUpkeep_reverts_ifUpkeepNotNeeded() public {
        // no players, no balance
        vm.expectRevert();
        raffle.performUpkeep("");
    }

    function test_performUpkeep_setsStateToCalculating() public maxPlayersEntered {
        raffle.performUpkeep("");

        assertEq(uint256(raffle.getRaffleState()), uint256(Raffle.RaffleState.CALCULATING));
    }

    /*//////////////////////////////////////////////////////////////
                           GETTERS TESTS
    //////////////////////////////////////////////////////////////*/
    function test_getterFunctions_returns_accurateValues() public view {
        assertEq(raffle.getEntranceFee(), ENTRANCE_FEE);
        assertEq(raffle.getMaxPlayers(), MAX_PLAYERS);
        assertEq(raffle.getPlayersCount(), 0);
        assertEq(uint256(raffle.getRaffleState()), uint256(Raffle.RaffleState.OPEN));
    }
}
