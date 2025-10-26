// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {console} from "lib/forge-std/src/console.sol";
import {Test} from "lib/forge-std/src/Test.sol";
import {Raffle} from "../src/Raffle.sol"; // Adjust this import depending on your folder structure
import {RaffleFactory} from "../src/RaffleFactory.sol";
import {DeployRaffle} from "../script/DeployRaffle.s.sol";
import {HelperConfig, CodeConstants} from "../script/HelperConfig.s.sol";
import {VRFCoordinatorV2Mock} from
    "lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2Mock.sol";
import {MockToken} from "./mocks/TokenToFundVRF.sol";

contract RaffleTest is Test, CodeConstants {
    Raffle raffle;
    RaffleFactory factory;
    uint256 constant ENTRANCE_FEE = 0.01 ether;

    address public PLAYER = makeAddr("player1");
    uint256 public STARTING_BALANCE = 10 ether;
    uint8 public constant MAX_PLAYERS = 10;

    /* Events */
    event RaffleEntered(address indexed player);
    event WaitingForMorePlayers(uint256 currentPlayers, uint8 maxPlayers);
    event WinnerPicked(address indexed winner);

    function setUp() public {
        DeployRaffle deployer = new DeployRaffle();
        (raffle) = deployer.deployRaffle();
        console.log(address(raffle));
        vm.deal(PLAYER, STARTING_BALANCE);
    }

    modifier raffleEntered() {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: ENTRANCE_FEE}();
        _;
    }

    modifier maxPlayersEntered() {
        // Fill up the raffle with 5 players
        for (uint160 i = 1; i <= 10; i++) {
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

        vm.startPrank(PLAYER);
        vm.expectRevert();
        raffle.enterRaffle{value: ENTRANCE_FEE}();
        vm.stopPrank();
    }

    function test_enterRaffle_reverts_IfRaffleIsFull() public maxPlayersEntered {
        //raffle should be full (5/5 players)
        assertEq(raffle.getPlayersCount(), 10);

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
        (bool upkeepNeeded,) = raffle.checkUpkeep("");
        Raffle.RaffleState state = raffle.getRaffleState();
        assertEq(upkeepNeeded, true);
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
        uint256 getMaxPlayers = raffle.getMaxPlayers();
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
        uint256 entrsnce = raffle.getEntranceFee();
        assertEq(raffle.getEntranceFee(), ENTRANCE_FEE);
        assertEq(raffle.getMaxPlayers(), MAX_PLAYERS);
        assertEq(raffle.getPlayersCount(), 0);
        assertEq(uint256(raffle.getRaffleState()), uint256(Raffle.RaffleState.OPEN));
    }
}
