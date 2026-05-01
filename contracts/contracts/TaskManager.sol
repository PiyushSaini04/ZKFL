// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

interface IVerifier {
    function verify(bytes memory proof, uint256[] memory publicInputs) external view returns (bool);
}

contract TaskManager is ReentrancyGuard {
    IERC20 public token;
    IVerifier public verifier;

    struct Task {
        uint256 id;
        address creator;
        string modelType;
        uint256 rewardPool;
        uint256 rounds;
        uint256 minClients;
        uint256 stakeRequired;
        uint256 currentRound;
        bool isActive;
    }

    struct Client {
        bool isRegistered;
        uint256 stake;
        string merkleRoot;
    }

    struct Submission {
        string deltaCID;
        uint256 lossBefore;
        uint256 lossAfter;
    }

    uint256 public taskCounter;
    mapping(uint256 => Task) public tasks;
    mapping(uint256 => mapping(address => Client)) public taskClients;
    // taskId => round => client address => Submission
    mapping(uint256 => mapping(uint256 => mapping(address => Submission))) public submissions;
    // taskId => round => number of submissions
    mapping(uint256 => mapping(uint256 => uint256)) public roundSubmissionCount;

    event TaskCreated(uint256 indexed taskId, address indexed creator, string modelType, uint256 rewardPool);
    event ClientJoined(uint256 indexed taskId, address indexed client, string merkleRoot);
    event UpdateSubmitted(uint256 indexed taskId, uint256 indexed round, address indexed client, string deltaCID);
    event RoundComplete(uint256 indexed taskId, uint256 indexed round);

    constructor(address _tokenAddress, address _verifierAddress) {
        token = IERC20(_tokenAddress);
        verifier = IVerifier(_verifierAddress);
    }

    function createTask(
        string memory _modelType,
        uint256 _rewardPool,
        uint256 _rounds,
        uint256 _minClients,
        uint256 _stakeRequired
    ) external nonReentrant {
        require(token.transferFrom(msg.sender, address(this), _rewardPool), "Transfer failed");

        taskCounter++;
        tasks[taskCounter] = Task({
            id: taskCounter,
            creator: msg.sender,
            modelType: _modelType,
            rewardPool: _rewardPool,
            rounds: _rounds,
            minClients: _minClients,
            stakeRequired: _stakeRequired,
            currentRound: 1,
            isActive: true
        });

        emit TaskCreated(taskCounter, msg.sender, _modelType, _rewardPool);
    }

    function joinTask(uint256 _taskId, string memory _merkleRoot) external nonReentrant {
        Task storage task = tasks[_taskId];
        require(task.isActive, "Task not active");
        require(!taskClients[_taskId][msg.sender].isRegistered, "Already registered");

        require(token.transferFrom(msg.sender, address(this), task.stakeRequired), "Stake transfer failed");

        taskClients[_taskId][msg.sender] = Client({
            isRegistered: true,
            stake: task.stakeRequired,
            merkleRoot: _merkleRoot
        });

        emit ClientJoined(_taskId, msg.sender, _merkleRoot);
    }

    function submitUpdate(
        uint256 _taskId,
        uint256 _round,
        string memory _deltaCID,
        uint256 _lossBefore,
        uint256 _lossAfter,
        bytes memory _proofData
    ) external {
        Task storage task = tasks[_taskId];
        require(task.isActive, "Task not active");
        require(task.currentRound == _round, "Invalid round");
        require(taskClients[_taskId][msg.sender].isRegistered, "Not registered");
        require(bytes(submissions[_taskId][_round][msg.sender].deltaCID).length == 0, "Already submitted");

        uint256[] memory publicInputs = new uint256[](2);
        publicInputs[0] = _lossBefore;
        publicInputs[1] = _lossAfter;

        require(verifier.verify(_proofData, publicInputs), "Invalid proof");
        require(_lossAfter < _lossBefore, "Loss must decrease");

        submissions[_taskId][_round][msg.sender] = Submission({
            deltaCID: _deltaCID,
            lossBefore: _lossBefore,
            lossAfter: _lossAfter
        });

        roundSubmissionCount[_taskId][_round]++;
        emit UpdateSubmitted(_taskId, _round, msg.sender, _deltaCID);

        if (roundSubmissionCount[_taskId][_round] == task.minClients) {
            emit RoundComplete(_taskId, _round);
            if (_round == task.rounds) {
                task.isActive = false; // All rounds completed
            } else {
                task.currentRound++;
            }
        }
    }
}
