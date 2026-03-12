//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {Raffle} from "../../src/Raffle.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {LinkToken} from "test/mocks/LinkToken.sol";


contract TestRaffle is Test {
    
    Raffle public raffle;
    HelperConfig public helperConfig;

    address public PLAYER = makeAddr("PLAYER");
    uint256 public constant STARTING_PLAYER_BALANCE = 10 ether;

    uint256 public entranceFee;
    uint256 public interval;
    address public vrfCoodinator2_5;
    uint256 public subscriptionId;
    bytes32 public gasLane;
    uint256 public callbackGasLimit;
    LinkToken public linkToken;

    //Events;

    event EnteredRaffle(address indexed player);


    function setUp() external {
        DeployRaffle deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.run();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        
        entranceFee = config.entranceFee;
        interval = config.interval;
        vrfCoodinator2_5 = config.vrfCoodinator;
        gasLane = config.gasLane;
        subscriptionId = config.subscriptionId;
        callbackGasLimit = config.callbackGasLimit;
        linkToken = LinkToken(config.linkToken);

        vm.deal(PLAYER, STARTING_PLAYER_BALANCE);


    }


    function testRaffleRevertWhenYouDontPayEnough() public {
        //Arrange
        vm.prank(PLAYER);

        //Act

        vm.expectRevert(Raffle.Raffle__NotEnoughETHSent.selector);
        raffle.enterRaffle();
        //Assertq
    }
    
    function testRaffleRecoedPlayersWhenTheyEnter() public {
        //Arrange
        vm.prank(PLAYER);
       
        //Act
        raffle.enterRaffle{value: entranceFee}();
        //Assert

        address playerRecord = raffle.getPlayer(0);
        assert(playerRecord==PLAYER);
    }


    function testEmitsEventOnTest() public {
        //Arrange 
        vm.prank(PLAYER);
        //Act 
        vm.expectEmit(true, false, false, false, address(raffle));
        emit EnteredRaffle(PLAYER);
        //Assert
        raffle.enterRaffle{value: entranceFee}();
    }

    function testDontAllowPalyersWhileCalculating() public {
        //Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();

        vm.warp(block.timestamp+interval+1);

        vm.roll(block.number+1);
        raffle.performUpkeep("");

        //Act//assert

        vm.expectRevert(Raffle.Raffel_StateNotOpen.selector);
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        

    }
}