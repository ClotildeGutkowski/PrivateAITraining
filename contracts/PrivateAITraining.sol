// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { FHE, euint32, ebool, euint8, euint16 } from "@fhevm/solidity/lib/FHE.sol";
import { SepoliaConfig } from "@fhevm/solidity/config/ZamaConfig.sol";

// Contract Address: 0x9892738a836A2a511096dc2855AfF0489cB6e840
contract PrivateAITraining is SepoliaConfig {

    address public owner;
    uint256 public trainingSessionCount;
    uint256 public modelCount;

    struct TrainingData {
        euint32[] features;
        euint8 label;
        address contributor;
        uint256 timestamp;
        bool isValid;
    }

    struct Model {
        euint32[] weights;
        euint32[] biases;
        uint256 trainingRounds;
        uint256 accuracy;
        address trainer;
        bool isComplete;
        uint256 createdAt;
    }

    struct TrainingSession {
        uint256 modelId;
        address[] contributors;
        uint256 dataCount;
        uint256 startTime;
        uint256 endTime;
        bool isActive;
        euint32 learningRate;
    }

    mapping(uint256 => Model) public models;
    mapping(uint256 => TrainingSession) public trainingSessions;
    mapping(uint256 => mapping(uint256 => TrainingData)) public trainingDataset;
    mapping(address => uint256) public contributorRewards;
    mapping(address => bool) public authorizedTrainers;

    event ModelCreated(uint256 indexed modelId, address indexed trainer);
    event TrainingSessionStarted(uint256 indexed sessionId, uint256 indexed modelId);
    event DataContributed(uint256 indexed sessionId, address indexed contributor, uint256 dataIndex);
    event TrainingCompleted(uint256 indexed sessionId, uint256 accuracy);
    event RewardDistributed(address indexed contributor, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    modifier onlyAuthorizedTrainer() {
        require(authorizedTrainers[msg.sender] || msg.sender == owner, "Not authorized trainer");
        _;
    }

    modifier validSession(uint256 sessionId) {
        require(sessionId < trainingSessionCount, "Invalid session");
        require(trainingSessions[sessionId].isActive, "Session not active");
        _;
    }

    constructor() {
        owner = msg.sender;
        authorizedTrainers[msg.sender] = true;
        trainingSessionCount = 0;
        modelCount = 0;
    }

    function authorizeTrainer(address trainer) external onlyOwner {
        authorizedTrainers[trainer] = true;
    }

    function revokeTrainer(address trainer) external onlyOwner {
        authorizedTrainers[trainer] = false;
    }

    // Create a new AI model with encrypted weights
    function createModel(
        uint32[] memory initialWeights,
        uint32[] memory initialBiases
    ) external onlyAuthorizedTrainer returns (uint256) {
        require(initialWeights.length > 0, "Weights required");
        require(initialBiases.length > 0, "Biases required");

        uint256 modelId = modelCount++;

        // Encrypt initial weights and biases
        euint32[] memory encryptedWeights = new euint32[](initialWeights.length);
        euint32[] memory encryptedBiases = new euint32[](initialBiases.length);

        for (uint i = 0; i < initialWeights.length; i++) {
            encryptedWeights[i] = FHE.asEuint32(initialWeights[i]);
            FHE.allowThis(encryptedWeights[i]);
        }

        for (uint i = 0; i < initialBiases.length; i++) {
            encryptedBiases[i] = FHE.asEuint32(initialBiases[i]);
            FHE.allowThis(encryptedBiases[i]);
        }

        models[modelId] = Model({
            weights: encryptedWeights,
            biases: encryptedBiases,
            trainingRounds: 0,
            accuracy: 0,
            trainer: msg.sender,
            isComplete: false,
            createdAt: block.timestamp
        });

        emit ModelCreated(modelId, msg.sender);
        return modelId;
    }

    // Start a new training session
    function startTrainingSession(
        uint256 modelId,
        uint32 learningRate
    ) external onlyAuthorizedTrainer returns (uint256) {
        require(modelId < modelCount, "Invalid model");
        require(!models[modelId].isComplete, "Model training complete");

        uint256 sessionId = trainingSessionCount++;

        euint32 encryptedLearningRate = FHE.asEuint32(learningRate);
        FHE.allowThis(encryptedLearningRate);

        trainingSessions[sessionId] = TrainingSession({
            modelId: modelId,
            contributors: new address[](0),
            dataCount: 0,
            startTime: block.timestamp,
            endTime: 0,
            isActive: true,
            learningRate: encryptedLearningRate
        });

        emit TrainingSessionStarted(sessionId, modelId);
        return sessionId;
    }

    // Contribute encrypted training data
    function contributeTrainingData(
        uint256 sessionId,
        uint32[] memory features,
        uint8 label
    ) external validSession(sessionId) {
        require(features.length > 0, "Features required");

        TrainingSession storage session = trainingSessions[sessionId];
        uint256 dataIndex = session.dataCount++;

        // Encrypt features
        euint32[] memory encryptedFeatures = new euint32[](features.length);
        for (uint i = 0; i < features.length; i++) {
            encryptedFeatures[i] = FHE.asEuint32(features[i]);
            FHE.allowThis(encryptedFeatures[i]);
        }

        // Encrypt label
        euint8 encryptedLabel = FHE.asEuint8(label);
        FHE.allowThis(encryptedLabel);

        trainingDataset[sessionId][dataIndex] = TrainingData({
            features: encryptedFeatures,
            label: encryptedLabel,
            contributor: msg.sender,
            timestamp: block.timestamp,
            isValid: true
        });

        session.contributors.push(msg.sender);

        emit DataContributed(sessionId, msg.sender, dataIndex);
    }

    // Perform encrypted training computation
    function performTrainingStep(
        uint256 sessionId
    ) external onlyAuthorizedTrainer validSession(sessionId) {
        TrainingSession storage session = trainingSessions[sessionId];
        require(session.dataCount > 0, "No training data");

        Model storage model = models[session.modelId];

        // Simplified encrypted gradient descent
        // In real implementation, this would involve complex FHE computations
        for (uint i = 0; i < session.dataCount; i++) {
            TrainingData storage data = trainingDataset[sessionId][i];
            if (data.isValid) {
                _updateWeights(model, data, session.learningRate);
            }
        }

        model.trainingRounds++;
    }

    // Internal function to update model weights with encrypted computation
    function _updateWeights(
        Model storage model,
        TrainingData storage data,
        euint32 learningRate
    ) internal {
        // Simplified weight update using FHE operations
        // Real implementation would compute gradients and update weights
        for (uint i = 0; i < model.weights.length && i < data.features.length; i++) {
            // Simplified: weight = weight + learningRate * feature * error
            euint32 adjustment = FHE.mul(learningRate, data.features[i]);
            model.weights[i] = FHE.add(model.weights[i], adjustment);
            FHE.allowThis(model.weights[i]);
        }
    }

    // Complete training session and evaluate model
    function completeTraining(uint256 sessionId) external onlyAuthorizedTrainer validSession(sessionId) {
        TrainingSession storage session = trainingSessions[sessionId];
        session.isActive = false;
        session.endTime = block.timestamp;

        Model storage model = models[session.modelId];

        // Simplified accuracy calculation
        uint256 accuracy = _calculateAccuracy(sessionId);
        model.accuracy = accuracy;

        if (accuracy > 80) { // 80% threshold
            model.isComplete = true;
        }

        // Distribute rewards to contributors
        _distributeRewards(sessionId);

        emit TrainingCompleted(sessionId, accuracy);
    }

    // Calculate model accuracy using encrypted computations
    function _calculateAccuracy(uint256 sessionId) internal view returns (uint256) {
        // Simplified accuracy calculation
        // In real implementation, this would use encrypted predictions
        TrainingSession storage session = trainingSessions[sessionId];

        if (session.dataCount == 0) return 0;

        // For demonstration, return a calculated accuracy based on data count
        return (session.dataCount * 85) / 100; // Simplified calculation
    }

    // Distribute rewards to data contributors
    function _distributeRewards(uint256 sessionId) internal {
        TrainingSession storage session = trainingSessions[sessionId];
        uint256 rewardPerContributor = 100; // Simplified reward amount

        for (uint i = 0; i < session.contributors.length; i++) {
            address contributor = session.contributors[i];
            contributorRewards[contributor] += rewardPerContributor;
            emit RewardDistributed(contributor, rewardPerContributor);
        }
    }

    // Get model information (non-sensitive data only)
    function getModelInfo(uint256 modelId) external view returns (
        uint256 trainingRounds,
        uint256 accuracy,
        address trainer,
        bool isComplete,
        uint256 createdAt
    ) {
        require(modelId < modelCount, "Invalid model");
        Model storage model = models[modelId];

        return (
            model.trainingRounds,
            model.accuracy,
            model.trainer,
            model.isComplete,
            model.createdAt
        );
    }

    // Get training session information
    function getSessionInfo(uint256 sessionId) external view returns (
        uint256 modelId,
        uint256 dataCount,
        uint256 startTime,
        uint256 endTime,
        bool isActive,
        uint256 contributorCount
    ) {
        require(sessionId < trainingSessionCount, "Invalid session");
        TrainingSession storage session = trainingSessions[sessionId];

        return (
            session.modelId,
            session.dataCount,
            session.startTime,
            session.endTime,
            session.isActive,
            session.contributors.length
        );
    }

    // Check contributor rewards
    function getContributorRewards(address contributor) external view returns (uint256) {
        return contributorRewards[contributor];
    }

    // Withdraw contributor rewards
    function withdrawRewards() external {
        uint256 rewards = contributorRewards[msg.sender];
        require(rewards > 0, "No rewards available");

        contributorRewards[msg.sender] = 0;
        // In real implementation, this would transfer tokens or ETH
        // For demonstration, we just emit an event
        emit RewardDistributed(msg.sender, rewards);
    }

    // Emergency function to pause all training
    function emergencyPause() external onlyOwner {
        // Pause all active sessions
        for (uint i = 0; i < trainingSessionCount; i++) {
            trainingSessions[i].isActive = false;
        }
    }
}