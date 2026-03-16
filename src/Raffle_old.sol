/*  Layout of the contract file:
 version
 imports
 errors
 interfaces, libraries, contract
 Inside Contract:
 Type declarations
 State variables
 Events
 Modifiers
 Functions */

//SPDX-License_identifier: MIT

pragma solidity ^0.8.18;

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import {AutomationCompatibleInterface} from "@chainlink/contracts/src/v0.8/automation/interfaces/AutomationCompatibleInterface.sol";

/** 
     * @title Raffle is a sample Contract 
     * @author Pratik Das
     * @notice This contract is for creating a sample Raffle Contract
     * @dev It implements ChainLinks VRFv2.5 and ChainLinks Auntomation
*/

contract Raffle is VRFConsumerBaseV2, AutomationCompatibleInterface {

    //errors
    error Raffle__NotEnoughETHSent();
    error Raffle__TimeStampNotPassed();
    error Raffle__TransferFailed();
    error Raffel_StateNotOpen();
    error Raffle__UpkeepNotNeeded(uint256 currentBalance, uint256 numPlayers, uint256 raffleState);

    //State Variables
    enum RaffleState{
        OPEN,
        CALCULTING
    }

    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;
    RaffleState private s_raffleState;
    uint256 private immutable i_entranceFee;
    uint256 private immutable i_interval;
    uint256 private s_lastTimeStamp;
    address payable[] private s_players;
    address payable private s_recentWinner;


    //events
    event EnteredRaffle(address indexed player);
    event PickedWinner(address winner);
    event RequestedRaffleWinner(uint256 indexed requestId);

    constructor (uint256 entranceFee, uint256 interval, address vrfCoodinator, bytes32 gasLane, uint64 subscriptionId, uint32 callbackGasLimit) VRFConsumerBaseV2(vrfCoodinator){
        i_entranceFee = entranceFee;
        i_interval = interval;
        s_lastTimeStamp = block.timestamp;

        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoodinator);
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;

        s_raffleState = RaffleState.OPEN;

    }

    function enterRaffle() public payable {
        if(msg.value < i_entranceFee){
            revert Raffle__NotEnoughETHSent();
        } 
        if(s_raffleState != RaffleState.OPEN){
            revert Raffel_StateNotOpen();
        } 

        s_players.push(payable(msg.sender));
        emit EnteredRaffle(msg.sender);
    }

  





    /** Getter function for entrance fee */

    

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable winner = s_players[indexOfWinner];
        s_recentWinner = winner;
        s_raffleState = RaffleState.OPEN;
        (bool success, ) = winner.call{value: address(this).balance}(""); // sending the entire balance of the contract to the winner's address
        if(!success) revert Raffle__TransferFailed(); //checking if the transfer was successful, if not then revert the transaction

        s_players = new address payable[](0); //resetting thr array after ther winner gets the prize money
        s_lastTimeStamp = block.timestamp; // resetting the timestamp after the winner is picked
        emit PickedWinner(winner); // emitting the event after the winner is picked

    }

    /**
     * @dev This is the function that ChainLink keeper nodes call
     * They look for the `upKeepNeeded` to return true
     * The following should be true ion order to return true:
     * 
     * 1. The time interval should be passed between raffle runs.
     * 2. when Raffle is open.
     * 3. The Contract should have Some Eth.
     * 4. The Players are registered.
     * 5. Implicity, your subscription is funded with Link.
     */

    

    function checkUpkeep(bytes memory /*checkdata*/) public view returns(bool upkeepNeeded, bytes memory /*performData*/){
        bool isOpen = RaffleState.OPEN == s_raffleState;
        bool timePassed = block.timestamp - s_lastTimeStamp > i_interval;
        bool hasBalance = address(this).balance > 0; 
        bool hasPlayers = s_players.length > 0;
        upkeepNeeded = (timePassed && isOpen && hasBalance && hasPlayers);

        return (upkeepNeeded, "0x0"); 

    }

        function performUpkeep(bytes calldata /* performdata */) external override {

        (bool upkeepNeeded, ) =  checkUpkeep("");

        if(!upkeepNeeded){
            revert Raffle__UpkeepNotNeeded(
                address(this).balance,
                s_players.length,
                uint256(s_raffleState)
            );
            
        }

        s_raffleState = RaffleState.CALCULTING;

        uint256 requestID = i_vrfCoordinator.requestRandomWords (
            i_gasLane,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );

        emit RequestedRaffleWinner(requestID);
    }


    function getPlayer(uint256 index) public view returns(address){
        return s_players[index];
    }

    function getEntranceFee() public view returns(uint256){
        return i_entranceFee;
    }

    function getRaffleState() public view returns(RaffleState){
        return s_raffleState;
    }
    function getRecentWWinner() public view returns(address){
        return s_recentWinner;
    }

    function getNumberOfPlayers() public view returns(uint256){
        return s_players.length;
    }
    
    function getLastTimeStamp() public view returns(uint256){
        return s_lastTimeStamp;
    }
}