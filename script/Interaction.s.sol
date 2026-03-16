//SPDX-License-Identifier: MIT


pragma solidity ^0.8.19;


import {Script, console} from "forge-std/Script.sol";
// import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2Mock.sol";
import {VRFCoordinatorV2PlusMock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2PlusMock.sol";

import {HelperConfig,CodeConstants} from "../script/HelperConfig.s.sol";
import {LinkToken} from "test/mocks/linkToken.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

contract CreateSubscription is Script {

    function createSubscriptionUsingConfig() public returns(uint256) {

        HelperConfig helperConfig = new HelperConfig();

    
        uint256 subsrciptionId = helperConfig.getConfig().subscriptionId;
        address vrfCoodinator = helperConfig.getConfig().vrfCoodinator;
        address linkToken = helperConfig.getConfig().linkToken;
        uint256 account = helperConfig.getConfig().account;
        return createSubscription(vrfCoodinator, account);

    }

    function createSubscription(address vrfCoodinator, uint256 account) public returns(uint256){

        console.log("Creating Subscription on ChainID: ", block.chainid);
        vm.startBroadcast(account);
        uint256 subId = VRFCoordinatorV2PlusMock(vrfCoodinator).createSubscription();
        vm.stopBroadcast();
        console.log("Your subId:", subId);
        console.log("Please update subscriptionId in HelperConfig!");
        return subId;

    } 

    function run() external returns(uint256) {
        return createSubscriptionUsingConfig();
    }


}


contract FundSubscription is Script, CodeConstants{
    uint256 public FUND_AMOUNT = 3 ether;

    function fundSubscriptionUsingConfig() public{
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoodinator = helperConfig.getConfig().vrfCoodinator;
        uint256 subscriptionId = helperConfig.getConfig().subscriptionId;
        address linkToken = helperConfig.getConfig().linkToken;
        uint256 account = helperConfig.getConfig().account;

        if(subscriptionId == 0){
            CreateSubscription createSub = new CreateSubscription();
            uint256 updateSubId = createSub.run();
            subscriptionId = updateSubId;
            subscriptionId = updateSubId;
            console.log("New SubId Created", subscriptionId, "VRF Address:", vrfCoodinator);
        }

        fundSubscription(vrfCoodinator, subscriptionId, linkToken, account);
    }

    function fundSubscription(address vrfCoodinator, uint256 subScriptionId, address linkToken, uint256 account) public {
        console.log("Funding Subvscription", subScriptionId);
        console.log("Using VRFCoodinator", vrfCoodinator);
        console.log("On chainId", block.chainid);

        // if(block.chainid == ETH_SEPOLIA_CHAIN_ID){
        //     vm.startBroadcast();

        //     VRFCoordinatorV2Mock(vrfCoodinator).fundSubscription(uint64(subScriptionId), uint96(FUND_AMOUNT));

        //     vm.stopBroadcast();
        // }else{
        //     console.log(LinkToken(linkToken).balanceOf(msg.sender));
        //     console.log(msg.sender);
        //     console.log(LinkToken(linkToken).balanceOf(address(this)));
        //     console.log(address(this));
        //     vm.startBroadcast();
        //     LinkToken(linkToken).transferAndCall(vrfCoodinator, FUND_AMOUNT, abi.encode(subScriptionId));
        //     vm.stopBroadcast();
        // }

        if(block.chainid == LOCAL_CHAIN_ID){
            vm.startBroadcast(account);
            // Mock cheatcode
            VRFCoordinatorV2PlusMock(vrfCoodinator).fundSubscription(uint256(subScriptionId), uint96(FUND_AMOUNT)); 
            vm.stopBroadcast();
        } else {
            vm.startBroadcast(account);
            // Real ERC677 transfer
            LinkToken(linkToken).transferAndCall(vrfCoodinator, FUND_AMOUNT, abi.encode(subScriptionId));
            vm.stopBroadcast();
        }





    }

    

    function run() external {
        fundSubscriptionUsingConfig();
    }
}


contract AddConsumer is Script{

    function addConsumer(address raffle, address vrfCoodinator, uint256 subscriptionId, uint256 account) public {
        console.log("Adding consumer contract: ", raffle);
        console.log("Using VrfCoodinator:", vrfCoodinator);
        console.log("On chain Id:", block.chainid);


        vm.startBroadcast();
        VRFCoordinatorV2PlusMock(vrfCoodinator).addConsumer(uint256(subscriptionId), raffle);
        vm.stopBroadcast();
    }

    function addConsumerUsingConfig(address raffle) public {
        HelperConfig helperconfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperconfig.getConfig();

        address vrfCoodinator = config.vrfCoodinator;
        uint256 subscriptionId = config.subscriptionId;
        uint256 account = config.account;
        addConsumer(raffle, vrfCoodinator, subscriptionId, account);
        
    }

    function run() external {
        address raffle = DevOpsTools.get_most_recent_deployment("MyContract: ", block.chainid);
        addConsumerUsingConfig(raffle);
    }

}