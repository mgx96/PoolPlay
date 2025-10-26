// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {console} from "lib/forge-std/src/console.sol";
import {Script} from "lib/forge-std/src/Script.sol";
import {
    VRFCoordinatorV2Mock
} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2Mock.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

contract CreateSubscription is Script {
    function createSubscriptionConfig() public returns (uint64, address) {
        HelperConfig config = new HelperConfig();
        address vrfCoordinator = config.getConfigByChainId(block.chainid).vrfCoordinator;
        uint256 account = config.getConfigByChainId(block.chainid).account;
        console.log("vrfCoordinator:", vrfCoordinator, "account:", account);
        return createSubscription(vrfCoordinator, account);
    }

    function createSubscription(address vrfCoordinator, uint256 account) public returns (uint64, address) {
        console.log("Creating subscription on chainId:", block.chainid);
        vm.startBroadcast(account);
        uint64 subId = VRFCoordinatorV2Mock(vrfCoordinator).createSubscription();
        vm.stopBroadcast();

        console.log("Subscription created! Subscription id:", subId);

        return (subId, vrfCoordinator);
    }

    function run() external returns (uint64, address) {
        console.log("Running CreateSubscription script...");
        return createSubscriptionConfig();
    }
}

contract FundSbuscription is Script {
    uint96 public constant FUND_TOKRN_AMOUNT = 3 ether;

    function fundSubscriptionUsingConfig() public payable {
        console.log("Creating subscription on chainId:", block.chainid);
        HelperConfig config = new HelperConfig();
        address vrfCoordinator = config.getConfigByChainId(block.chainid).vrfCoordinator;
        uint256 account = config.getConfigByChainId(block.chainid).account;
        uint256 subsId = config.getConfigByChainId(block.chainid).subscriptionId;
        address fundToken = config.getConfigByChainId(block.chainid).link;
        console.log();
        if (subsId == 0) {
            console.log("No subscription found, creating a new one...");
            CreateSubscription createSubs = new CreateSubscription();
            (uint256 newSubsid, address vrfCoOrdinator2) = createSubs.createSubscription(vrfCoordinator, account);
            subsId = newSubsid;
            vrfCoordinator = vrfCoOrdinator2;
        }

        fundSubscription(vrfCoordinator, fundToken, account, uint64(subsId));
    }

    function fundSubscription(
        address _vrf,
        address,
        /*_fundToken*/
        uint256 _account,
        uint64 _subID
    )
        public
    {
        console.log("Funding subscription on chainId:", block.chainid);
        console.log("SubscriptionId:", _subID, "VRFCoordinator:", _vrf);

        if (block.chainid == 31337) {
            vm.startBroadcast(_account);
            VRFCoordinatorV2Mock(_vrf).fundSubscription(_subID, FUND_TOKRN_AMOUNT);
            vm.stopBroadcast();
            console.log("Subscription funded with", FUND_TOKRN_AMOUNT, "wei");
        } else {
            console.log("Live network logic not implemented yet");
        }
    }

    function run() external {
        fundSubscriptionUsingConfig();
    }
}

contract AddConsumer is Script {
    function run() public {
        address recentRaffle = DevOpsTools.get_most_recent_deployment("Raffle", block.chainid);
        console.log("Most recent Raffle deployed at:", recentRaffle);
        addConsumerByConfig(recentRaffle);
    }

    function addConsumerByConfig(address _mostRecentDEployedRaffle) public {
        HelperConfig config = new HelperConfig();
        address vrfCoordinator = config.getConfig().vrfCoordinator;
        uint256 account = config.getConfig().account;
        uint256 subsCriptionId = config.getConfig().subscriptionId;

        if (subsCriptionId == 0) {
            console.log("No subscription found, creating a new one...");
            CreateSubscription createSubs = new CreateSubscription();
            (uint64 newSubsid, address vrfCoOrdinator2) = createSubs.createSubscription(vrfCoordinator, account);
            subsCriptionId = newSubsid;
            vrfCoordinator = vrfCoOrdinator2;
        }

        addconsum(_mostRecentDEployedRaffle, uint64(subsCriptionId), vrfCoordinator, account);
    }

    function addconsum(address _contractToAddAsCOns, uint64 _subscriptionId, address _crfContract, uint256 _account)
        public
    {
        vm.startBroadcast(_account);
        VRFCoordinatorV2Mock(_crfContract).addConsumer(_subscriptionId, _contractToAddAsCOns);
        vm.stopBroadcast();
    }
}
