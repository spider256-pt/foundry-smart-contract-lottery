//SPDX-License-Identifier: MIT


pragma solidity ^0.8.18;


import {Script, console} from "forge-std/Script.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2Mock.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";
import {CodeConstants} from "../script/HelperConfig.s.sol";
import {LinkToken} from "test/mocks/linkToken.sol";

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

        if(block.chainid == ETH_SEPOLIA_CHAIN_ID){
            vm.startBroadcast();

            VRFCoordinatorV2Mock(vrfCoodinator).fundSubscription(uint64(subScriptionId), uint96(FUND_AMOUNT));

            vm.stopBroadcast();
        }else{
            console.log(LinkToken(linkToken).balanceOf(msg.sender));
            console.log(msg.sender);
            console.log(LinkToken(linkToken).balanceOf(address(this)));
            console.log(address(this));
            vm.startBroadcast();
            LinkToken(linkToken).transferAndCall(vrfCoodinator, FUND_AMOUNT, abi.encode(subScriptionId));
            vm.stopBroadcast();
        }
    }

    

    function run() external {
        fundSubscriptionUsingConfig();
    }
}