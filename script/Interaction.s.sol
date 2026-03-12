//SPDX-License-Identifier: MIT


pragma solidity ^0.8.18;


import {Script, console} from "forge-std/Script.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2Mock.sol";
import {HelperConfig,CodeConstants} from "../script/HelperConfig.s.sol";
import {LinkToken} from "test/mocks/linkToken.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

contract CreateSubscription is Script {

    function createSubscriptionUsingConfig() public returns(uint64) {

        HelperConfig helperConfig = new HelperConfig();

    
        uint256 subsrciptionId = helperConfig.getConfig().subscriptionId;
        address vrfCoodinator = helperConfig.getConfig().vrfCoodinator;
        address linkToken = helperConfig.getConfig().linkToken;
        return createSubscription(vrfCoodinator);

    }

    function createSubscription(address vrfCoodinator) public returns(uint64){

        console.log("Creating Subscription on ChainID: ", block.chainid);
        vm.startBroadcast();
        uint64 subId = VRFCoordinatorV2Mock(vrfCoodinator).createSubscription();
        vm.stopBroadcast();
        console.log("Your subId:", subId);
        console.log("Please update subscriptionId in HelperConfig!");
        return subId;

    } 

    function run() external returns(uint64) {
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

        if(subscriptionId == 0){
            CreateSubscription createSub = new CreateSubscription();
            uint64 updateSubId = createSub.run();
            subscriptionId = updateSubId;
            subscriptionId = updateSubId;
            console.log("New SubId Created", subscriptionId, "VRF Address:", vrfCoodinator);
        }

        fundSubscription(vrfCoodinator, subscriptionId, linkToken);
    }

    function fundSubscription(address vrfCoodinator, uint256 subScriptionId, address linkToken) public {
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
            vm.startBroadcast();
            // Mock cheatcode
            VRFCoordinatorV2Mock(vrfCoodinator).fundSubscription(uint64(subScriptionId), uint96(FUND_AMOUNT)); 
            vm.stopBroadcast();
        } else {
            vm.startBroadcast();
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

    function addConsumer(address raffle, address vrfCoodinator, uint256 subscriptionId) public {
        console.log("Adding consumer contract: ", raffle);
        console.log("Using VrfCoodinator:", vrfCoodinator);
        console.log("On chain Id:", block.chainid);


        vm.startBroadcast();
        VRFCoordinatorV2Mock(vrfCoodinator).addConsumer(uint64(subscriptionId), raffle);
        vm.stopBroadcast();
    }

    function addConsumerUsingConfig(address raffle) public {
        HelperConfig helperconfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperconfig.getConfig();

        address vrfCoodinator = config.vrfCoodinator;
        uint64 subscriptionId = config.subscriptionId;
        addConsumer(raffle, vrfCoodinator, subscriptionId);
        
    }

    function run() external {
        address raffle = DevOpsTools.get_most_recent_deployment("MyContract: ", block.chainid);
        addConsumerUsingConfig(raffle);
    }

}