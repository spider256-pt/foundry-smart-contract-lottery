//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {Raffle} from "../../src/Raffle.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {LinkToken} from "test/mocks/LinkToken.sol";
import {Vm} from "forge-std/Vm.sol";
//  import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2Mock.sol";
import {VRFCoordinatorV2PlusMock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2PlusMock.sol";


contract TestRaffle is Test {
    
    Raffle public raffle;
    HelperConfig public helperConfig;
    // VRFCoordinatorV2Mock public vrfCoordinator;

    address public PLAYER = makeAddr("PLAYER");
    uint256 public constant STARTING_PLAYER_BALANCE = 10 ether;

    uint256 public entranceFee;
    uint256 public interval;
    address public vrfCoodinator;
    uint256 public subscriptionId;
    bytes32 public gasLane;
    uint256 public callbackGasLimit;
    LinkToken public linkToken;
    uint256 account;
    address expectedWinner;

    //Events;

    event EnteredRaffle(address indexed player);


    modifier raffleEnteredAndTimePassed(){
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp+interval+1);
        vm.roll(block.number+1);
        _;
    }

    modifier forkskip(){
        if(block.chainid != 31337){
            return;
        }
        _;
    }


    function setUp() external {
        DeployRaffle deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.run();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        
        
        entranceFee = config.entranceFee;
        interval = config.interval;
        vrfCoodinator = config.vrfCoodinator;
        gasLane = config.gasLane;
        subscriptionId = config.subscriptionId;
        callbackGasLimit = config.callbackGasLimit;
        linkToken = LinkToken(config.linkToken);
        account = config.account;

        vm.deal(PLAYER, STARTING_PLAYER_BALANCE);


    }


    function testRaffleRevertWhenYouDontPayEnough() public {
        //Arrange
        vm.prank(PLAYER);

        //Act
        vm.expectRevert(Raffle.Raffle__NotEnoughEthSent.selector);
        raffle.enterRaffle();

        //Assertq
    }
    
    function testRaffleRecordPlayersWhenTheyEnter() public {
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

        vm.expectRevert(Raffle.Raffle__RaffleNotOpen.selector);
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        

    }

    function testCheckUpKeepReturnsFalseIfItHasNoBalance() public {
        //Arrange
        vm.warp(block.timestamp+interval+ 1);
        vm.roll(block.number+1);
        //Act
        (bool upkeepNeeded, ) = raffle.checkUpkeep(""); 
        //Assert
        assert(!upkeepNeeded);
    }

    
    function testCheckUpkeepReturnsFalseIfRaffleNotOpen() public {
        //Arrange 
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp+interval+1);
        vm.roll(block.number+1);
        raffle.performUpkeep("");

        Raffle.RaffleState raffleState = raffle.getRaffleState();

        //Act 
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");

        //Assert

        assert(raffleState == Raffle.RaffleState.CALCULATING);
        assert(upkeepNeeded == false);

    }


    function testCheckUpkeepReturnsFalseIfEnoughTimeHasntPassed() public {
        
        //Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        //Act
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");

        //Assert
        assert(upkeepNeeded == false);

    }

    function testCheckUpkeepReturnsTrueWhenParametersGood() public{
        //Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp+interval+1);
        vm.roll(block.number+1);
        //Act
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");

        //Assert
        assert(upkeepNeeded);
    }


    function testPerformUpkeepCanOnlyRunIfCheckUpkeepIsTrue() public {
        //Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value:entranceFee}();
        vm.warp(block.timestamp+interval+1);
        vm.roll(block.number+1);

        //Act//Assert
        raffle.performUpkeep("");

    }

    function testPerformUpkeepRevertsIfCheckUpkeepIsFalse() public{

        //Arrange

        uint256 balance = 0;
        uint256 numberPlayer = 0;
        Raffle.RaffleState raffleState = raffle.getRaffleState();
        //Act//assert
        vm.expectRevert(
            abi.encodeWithSelector(
                Raffle.Raffle__UpkeepNotNeeded.selector,
                balance,
                numberPlayer,
                raffleState
            )
        );
        raffle.performUpkeep("");

    }

    function testPerformUpkeepUpdatesRaffleStateAndEmitsRequestId() public raffleEnteredAndTimePassed {
        //Act
        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestedId = entries[1].topics[1];

        //Assert

        Raffle.RaffleState rafflestate= raffle.getRaffleState();
        assert(uint256(requestedId)>0);
        assert(uint(rafflestate)==1);
    }

    function testFulfillRandomWordsCanOnlyBeCalledAfterPerformUpkeep(uint256 RandomRequestId) public raffleEnteredAndTimePassed forkskip{
        //Arrange 

        //Act//Assert
        vm.expectRevert("nonexistent request");
        VRFCoordinatorV2PlusMock(vrfCoodinator).fulfillRandomWords(
            RandomRequestId, 
            address(raffle)
        );
    }


    function testFulfillRandomWordsPicksAWinnerResetsAndSendsMoney() public raffleEnteredAndTimePassed forkskip{
        //Arrange

        address expectedWinner = address(2);
        uint256 TotalEntrants = 2;
        uint256 StartingIndex = 1;
        
        uint256 startTimeStamp = raffle.getLastTimeStamp();

        for(uint256 i = StartingIndex; i < StartingIndex+TotalEntrants; i++) {
            address rafflePlayer = address(uint160(i));
            hoax(rafflePlayer, 1 ether);
            raffle.enterRaffle{value: entranceFee}();
        }
        
        uint256 WinnerPrize = entranceFee * (TotalEntrants+1);
        uint256 WinnerStartingBalance = expectedWinner.balance;
        
        //Act
        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];

        VRFCoordinatorV2PlusMock(vrfCoodinator).fulfillRandomWords(
            uint256(requestId),
            address(raffle)
        );


        //Assert
        address recentWinner = raffle.getRecentWinner();
        Raffle.RaffleState rafflestate = raffle.getRaffleState();
        uint256 WinnerBalance = recentWinner.balance;
        uint256 endTimeStamp = raffle.getLastTimeStamp();
        

        assert(expectedWinner == recentWinner);
        assert(uint256(rafflestate) == 0);
        assert(WinnerBalance == WinnerStartingBalance + WinnerPrize);
        assert(endTimeStamp > startTimeStamp); 
    }

        
}