// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {HelperConfig, CodeConstants} from "./HelperConfig.s.sol";
import {VRFCoordinatorV2_5Mock} from
    "lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {MockToken} from "../test/mocks/TokenToFundVRF.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

contract CreateSubscription is Script {
    function createSubscriptionUsingConfig() public returns (uint256, address) {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfigByChainId(block.chainid).vrfCoordinator;
        uint256 account = helperConfig.getConfigByChainId(block.chainid).account; // get the account from the config
        // create subscription
        // (uint256 subId, ) = createSubscription(vrfCoordinator, account);
        // return (uint64(subId), vrfCoordinator);
        return createSubscription(vrfCoordinator, account);
    }

    function createSubscription(address vrfCoordinator, uint256 account) public returns (uint256, address) {
        console.log("Creating subscription on ", block.chainid);
        vm.startBroadcast(account);
        uint256 subId = VRFCoordinatorV2_5Mock(vrfCoordinator).createSubscription();

        vm.stopBroadcast();
        console.log("Your Subscription id is: ", subId);
        console.log("Please update the subscriptionId in the HelperConfig.s.sol file");
        return (subId, vrfCoordinator);
    }

    function run() external returns (uint256, address) {
        return createSubscriptionUsingConfig();
    }
}

contract FundSubscription is Script {
    uint256 public constant FUND_AMOUNT = 3 ether;

    function fundSubscriptionUsingConfig() public payable {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        uint256 subscriptionId = helperConfig.getConfig().subscriptionId;
        uint256 account = helperConfig.getConfig().account;
        address mockToken = helperConfig.getConfig().token;

        if (subscriptionId == 0) {
            CreateSubscription createSub = new CreateSubscription();
            (uint256 updatedSubId, address updatedVRFv2) = createSub.run();
            subscriptionId = updatedSubId;
            vrfCoordinator = updatedVRFv2;
        }
        fundSubscription(vrfCoordinator, subscriptionId, account, mockToken);
    }

    function fundSubscription(
        address vrfCoordinator,
        uint256 subscriptionId, // address linkToken
        uint256,
        address
    ) public {
        console.log("Funding subscription on chainid ", block.chainid);
        console.log("with subscriptionId ", subscriptionId);
        console.log("and vrfCoordinator ", vrfCoordinator);
        if (block.chainid == 31337) {
            vm.startBroadcast();
            VRFCoordinatorV2_5Mock(vrfCoordinator).fundSubscription(subscriptionId, FUND_AMOUNT);
            vm.stopBroadcast();
        } else {
            // vm.startBroadcast();
            // MockToken(mockToken).mint(address(vrfCoordinator), 100 ether);
            // vm.stopBroadcast();
        }
    }

    function run() external {
        fundSubscriptionUsingConfig();
    }
}

contract AddConsumer is Script {
    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("Raffle", block.chainid);

        addConsumerUsingConfig(mostRecentlyDeployed);
    }

    function addConsumerUsingConfig(address mostRecentlyDeployed) public {
        HelperConfig helperConfig = new HelperConfig();
        uint256 subId = helperConfig.getConfig().subscriptionId;
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        uint256 account = helperConfig.getConfig().account;

        addConsumer(mostRecentlyDeployed, vrfCoordinator, subId, account);
    }

    function addConsumer(address contractToAddToVrf, address vrfCoordinator, uint256 subId, uint256 account) public {
        console.log("Adding consumer to contract: ", contractToAddToVrf);
        console.log("on vrfCoordinator: ", vrfCoordinator);
        console.log("with subscriptionId: ", subId);

        vm.startBroadcast(account);
        VRFCoordinatorV2_5Mock(vrfCoordinator).addConsumer(subId, contractToAddToVrf);
        vm.stopBroadcast();
    }
}
