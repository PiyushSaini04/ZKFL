// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./TaskManager.sol";

contract RewardDistributor is ReentrancyGuard {
    IERC20 public token;
    TaskManager public taskManager;

    mapping(uint256 => mapping(address => bool)) public hasClaimed;

    constructor(address _tokenAddress, address _taskManagerAddress) {
        token = IERC20(_tokenAddress);
        taskManager = TaskManager(_taskManagerAddress);
    }

    function claimReward(uint256 _taskId) external nonReentrant {
        require(!hasClaimed[_taskId][msg.sender], "Already claimed");
        
        (,,,, uint256 rounds, , uint256 stakeRequired, , bool isActive) = taskManager.tasks(_taskId);
        require(!isActive, "Task still active"); 
        
        uint256 userTotalLossReduction = 0;
        bool participatedAllRounds = true;
        for (uint256 r = 1; r <= rounds; r++) {
            (, uint256 lossB, uint256 lossA) = taskManager.submissions(_taskId, r, msg.sender);
            if (lossB == 0) {
                participatedAllRounds = false;
                break;
            }
            if (lossB > lossA) {
                userTotalLossReduction += (lossB - lossA);
            }
        }
        
        require(participatedAllRounds, "Did not participate in all rounds");
        hasClaimed[_taskId][msg.sender] = true;
        
        require(token.transfer(msg.sender, stakeRequired), "Stake refund failed");
        
        // Reward pool distribution would be implemented here based on userTotalLossReduction
        // relative to total loss reduction of all clients.
    }
}
