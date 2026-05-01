// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Aggregator is Ownable {
    // taskId => round => globalModelCID
    mapping(uint256 => mapping(uint256 => string)) public globalModels;

    event NewGlobalModel(uint256 indexed taskId, uint256 indexed round, string newModelCID);
    
    constructor() Ownable(msg.sender) {}

    function submitGlobalModel(uint256 _taskId, uint256 _round, string memory _newModelCID) external onlyOwner {
        globalModels[_taskId][_round] = _newModelCID;
        emit NewGlobalModel(_taskId, _round, _newModelCID);
    }
}
