//SPDX-License-Identifer: MIT

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "./Interaction.s.sol";


contract DeployRaffle is Script {

       
    function run() external returns(Raffle, HelperConfig) {
        //implementation 

        HelperConfig helperConfig = new HelperConfig();

       HelperConfig.NetworkConfig memory config = helperConfig.getConfig(); 

        if(config.subscriptionId == 0 ){
            CreateSubscription createsubscription = new CreateSubscription();
            config.subscriptionId = createsubscription.createSubscription(config.vrfCoodinator);

            FundSubscription fundSubscription = new FundSubscription();
            fundSubscription.fundSubscription(config.vrfCoodinator,config.subscriptionId,config.linkToken);
        }

        vm.startBroadcast();
            Raffle raffle = new Raffle(
                config.entranceFee,
                config.interval,
                config.vrfCoodinator,
                config.gasLane,
                config.subscriptionId,
                config.callbackGasLimit
            );

        vm.stopBroadcast();

        AddConsumer addConsumer = new AddConsumer();
        addConsumer.addConsumer(address(raffle), config.vrfCoodinator, config.subscriptionId);

        return(raffle, helperConfig);
    }


    // function deployContract() internal returns (Raffle, HelperConfig) {
        
    // }
    


}