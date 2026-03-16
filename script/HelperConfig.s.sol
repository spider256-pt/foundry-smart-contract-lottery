//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
// import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2Mock.sol";
import {VRFCoordinatorV2PlusMock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2PlusMock.sol";
import {LinkToken} from "test/mocks/linkToken.sol";



abstract contract CodeConstants {

    /* VRF MOCK Values */
    uint96 public constant MOCK_BASE_FEE = 0.25 ether;
    uint96 public constant MOCK_GAS_PRICE = 1e9;
    int256 public constant MOCK_WEI_PER_UINT_LINK = 4e15;


    uint256 public constant ETH_SEPOLIA_CHAIN_ID = 11155111;
    uint256 public constant LOCAL_CHAIN_ID = 31337;


    uint256 public constant ANVIL_ADDRESS = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80; 
}


contract HelperConfig is CodeConstants, Script{

    //errors
    error Helper__InvalidChainId();


    struct NetworkConfig{
        uint256 entranceFee;
        uint256 interval;
        address vrfCoodinator; 
        bytes32 gasLane;
        uint256 subscriptionId; 
        uint32 callbackGasLimit;
        address linkToken;
        uint256 account;
    }


    NetworkConfig public localNetworkConfig;
    mapping(uint256 chainId => NetworkConfig) public networkConfigs;

    constructor(){
        networkConfigs[ETH_SEPOLIA_CHAIN_ID] = getSepoliaEthConfig();
    }

 
    function getOrCreateAnvilEthConfig() public returns(NetworkConfig memory){

        if(localNetworkConfig.vrfCoodinator != address(0)){
            return localNetworkConfig;
        }

        vm.startBroadcast();

        VRFCoordinatorV2PlusMock vrfCoodinatorMock = new VRFCoordinatorV2PlusMock(MOCK_BASE_FEE,
         MOCK_GAS_PRICE);
        LinkToken linktoken = new LinkToken();
        vm.stopBroadcast();

        localNetworkConfig = NetworkConfig
        ({
            entranceFee: 0.01 ether,
            interval: 30,
            vrfCoodinator: address(vrfCoodinatorMock),
            gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            subscriptionId: 0,
            callbackGasLimit: 500_000,
            linkToken: address(linktoken),
            account: ANVIL_ADDRESS
         });
         return localNetworkConfig;

        
    }


    function getConfig() public returns(NetworkConfig memory){
        return getConfigByChainId(block.chainid);
    }

    function getConfigByChainId(uint256 chainId) public returns(NetworkConfig memory){
        if(networkConfigs[chainId].vrfCoodinator != address(0)){
            return networkConfigs[chainId];
        } else if(chainId == LOCAL_CHAIN_ID){
            return getOrCreateAnvilEthConfig();
        } else {
            revert Helper__InvalidChainId();
        }
    }

    function getSepoliaEthConfig() public view returns (NetworkConfig memory){

        return NetworkConfig
        ({
            entranceFee: 0.01 ether,
            interval: 30,
            vrfCoodinator: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
            gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            subscriptionId: 0,
            callbackGasLimit: 500000,
            linkToken: 0x779877A7B0D9E8603169DdbD7836e478b4624789,
            account: vm.envUint("PRIVATE_KEY")
            
         });

    }
        
    function getLocalConfig() public pure returns(NetworkConfig memory){
        return NetworkConfig({
            entranceFee: 0.01 ether,
            interval: 30,
            vrfCoodinator: address(0),
            gasLane:"",
            subscriptionId: 0,
            callbackGasLimit: 500000,
            linkToken: address(0),
            account: ANVIL_ADDRESS
        });

    }
    
}