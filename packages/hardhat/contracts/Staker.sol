// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;  //Do not change the solidity version as it negativly impacts submission grading

import "./ExampleExternalContract.sol";

/**
* @title Stacker Contract
* @author Kaviraj J
* @notice A contract that allow users to stack ETH
*/

contract Staker {

  ExampleExternalContract public exampleExternalContract;
  
  mapping (address => uint256) public balances;
  uint256 public constant THRESHOLD = 1 ether;
  uint256 public deadline = block.timestamp + 30 seconds;

  // Errors
  error Staker__ThresholdNotReached();
  error Staker__ThresholdAlreadyReached();
  error Staker__DeadlineNotReached();
  error Staker__DeadlineAlreadyReached();
  error Staker__StakeAlreadyCompleted();
  error Staker__NoBalanceToWithdraw();

  // Modifiers
  modifier thresholdReached( bool requiredThreshold ) {
    if(requiredThreshold) {
      if(address(this).balance < THRESHOLD) {
        revert Staker__ThresholdNotReached();
      }
    } else {
      if(address(this).balance >= THRESHOLD) {
        revert Staker__ThresholdAlreadyReached();
      }
    }
    _;
  }  

  modifier deadlineReached( bool requireReached ) {
    uint256 timeRemaining = timeLeft();
    if( requireReached ) {
      if(timeRemaining > 0) {
        revert Staker__DeadlineNotReached();
      }
    } else {
      if(timeRemaining == 0) {
        revert Staker__DeadlineAlreadyReached();
      }
    }
    _;
  }

  modifier stakeNotCompleted {
    if(exampleExternalContract.completed()) {
      revert Staker__StakeAlreadyCompleted();
    }
    _;
  }

  // Events
  event Stake(address stakerAddress, uint256 amount);

  constructor(address exampleExternalContractAddress) {
      exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
  }

  function stake() public deadlineReached(false) payable {
    balances[msg.sender] += msg.value;
    emit Stake(msg.sender, msg.value);
  }

  function execute() external deadlineReached(true) {
    if(address(this).balance >= THRESHOLD) {
      (bool success, ) = address(exampleExternalContract).call{value: address(this).balance}(abi.encodeWithSignature("complete()"));
      require(success, "Failed sending amount to the contract");
    }
  }

  function withdraw() external deadlineReached(true) thresholdReached(false) {
    if(balances[msg.sender] == 0) {
      revert Staker__NoBalanceToWithdraw();
    }
    (bool success, ) = msg.sender.call{value: balances[msg.sender]}("");
    balances[msg.sender] = 0;
    require(success, "Failed sending user balance");
  }


  function timeLeft() public view returns (uint256 timeleft) {
    if( block.timestamp >= deadline ) {
      return 0;
    } else {
      return deadline - block.timestamp;
    }
  }

  receive() payable external {
    stake();
  }

}
