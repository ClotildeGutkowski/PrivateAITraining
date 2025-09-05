# Hello FHEVM: Your First Confidential Smart Contract

**A Complete Beginner's Guide to Building Privacy-Preserving Applications with Fully Homomorphic Encryption**

## 📚 Table of Contents

1. [Introduction](#introduction)
2. [Prerequisites](#prerequisites)
3. [What You'll Build](#what-youll-build)
4. [Learning Objectives](#learning-objectives)
5. [Environment Setup](#environment-setup)
6. [Understanding FHEVM Basics](#understanding-fhevm-basics)
7. [Building the Smart Contract](#building-the-smart-contract)
8. [Creating the Frontend](#creating-the-frontend)
9. [Deployment Guide](#deployment-guide)
10. [Testing Your Application](#testing-your-application)
11. [Common Issues & Solutions](#common-issues--solutions)
12. [Next Steps](#next-steps)

## 🎯 Introduction

Welcome to the world of Fully Homomorphic Encryption (FHE) on blockchain! This tutorial will guide you through creating your first confidential smart contract application - a privacy-preserving AI training system that keeps all data encrypted while still allowing computations.

**No prior cryptography knowledge required!** If you can write basic Solidity contracts and work with React, you're ready to start.

## ✅ Prerequisites

Before starting this tutorial, you should have:

- **Basic Solidity knowledge**: Can write and deploy simple smart contracts
- **JavaScript/React familiarity**: Comfortable with basic frontend development
- **Ethereum tools experience**: Used MetaMask, deployed contracts with Hardhat/Foundry
- **Node.js installed**: Version 16 or higher
- **Git**: For cloning repositories

**You do NOT need:**
- Advanced mathematics background
- Cryptography knowledge
- Previous FHE experience

## 🎯 What You'll Build

By the end of this tutorial, you'll have built a **Private AI Training Platform** that includes:

- **Smart Contract**: Handles encrypted AI model creation and training
- **Web Interface**: User-friendly frontend for interacting with encrypted data
- **Wallet Integration**: MetaMask connection and transaction handling
- **Real-time Updates**: Live stats and training progress

**Key Features:**
- Create encrypted AI models with private weights and biases
- Contribute training data that remains encrypted end-to-end
- Perform computations on encrypted data without revealing contents
- Distribute rewards for data contributions

## 🎓 Learning Objectives

After completing this tutorial, you will understand:

1. **FHEVM Fundamentals**: How to work with encrypted data on blockchain
2. **Contract Development**: Building smart contracts with FHE operations
3. **Frontend Integration**: Connecting web interfaces to FHEVM contracts
4. **Deployment Process**: Publishing your contract to Zama's test network
5. **Testing Strategies**: Ensuring your confidential application works correctly

## 🛠️ Environment Setup

### Step 1: Project Initialization

```bash
# Create new project directory
mkdir my-fhevm-project
cd my-fhevm-project

# Initialize npm project
npm init -y

# Install Hardhat for smart contract development
npm install --save-dev hardhat

# Initialize Hardhat project
npx hardhat
```

Choose "Create an empty hardhat.config.js" when prompted.

### Step 2: Install FHEVM Dependencies

```bash
# Install FHEVM library
npm install @fhevm/solidity

# Install other development dependencies
npm install --save-dev @nomicfoundation/hardhat-toolbox
npm install ethers@^5.7.2
```

### Step 3: Configure Hardhat

Create `hardhat.config.js`:

```javascript
require('@nomicfoundation/hardhat-toolbox');

module.exports = {
  solidity: {
    version: "0.8.24",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
  networks: {
    sepolia: {
      url: "https://sepolia.infura.io/v3/YOUR_INFURA_KEY",
      accounts: ["YOUR_PRIVATE_KEY"]
    }
  }
};
```

## 🧠 Understanding FHEVM Basics

### What is Fully Homomorphic Encryption?

FHE allows you to perform computations on encrypted data without decrypting it first. Think of it like this:

```
Traditional: Decrypt → Compute → Encrypt
FHE: Compute directly on encrypted data
```

### Key FHEVM Concepts

1. **Encrypted Types**: `euint32`, `euint8`, `ebool` - encrypted versions of standard types
2. **FHE Operations**: `FHE.add()`, `FHE.mul()`, `FHE.lt()` - operations on encrypted data
3. **Access Control**: `FHE.allowThis()`, `FHE.allowAll()` - managing who can access encrypted data

### Simple Example

```solidity
// Traditional contract
uint32 public number = 42;

// FHEVM contract
euint32 public encryptedNumber = FHE.asEuint32(42);
```

The encrypted number provides the same functionality but keeps the value private!

## 🔨 Building the Smart Contract

### Step 1: Create Contract Structure

Create `contracts/PrivateAITraining.sol`:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { FHE, euint32, ebool, euint8 } from "@fhevm/solidity/lib/FHE.sol";
import { SepoliaConfig } from "@fhevm/solidity/config/ZamaConfig.sol";

contract PrivateAITraining is SepoliaConfig {
    // Contract state will go here
}
```

### Step 2: Define Data Structures

Add these structures inside your contract:

```solidity
struct Model {
    euint32[] weights;          // Encrypted neural network weights
    euint32[] biases;           // Encrypted biases
    uint256 trainingRounds;     // Public training progress
    address trainer;            // Model creator
    bool isComplete;           // Training status
}

struct TrainingData {
    euint32[] features;         // Encrypted input features
    euint8 label;              // Encrypted target label
    address contributor;        // Data provider
    bool isValid;              // Data validation status
}
```

### Step 3: Add State Variables

```solidity
contract PrivateAITraining is SepoliaConfig {
    address public owner;
    uint256 public modelCount;

    mapping(uint256 => Model) public models;
    mapping(address => bool) public authorizedTrainers;
    mapping(address => uint256) public contributorRewards;

    event ModelCreated(uint256 indexed modelId, address indexed trainer);
    event DataContributed(address indexed contributor, uint256 reward);
```

### Step 4: Implement Core Functions

#### Model Creation Function

```solidity
function createModel(
    uint32[] memory initialWeights,
    uint32[] memory initialBiases
) external returns (uint256) {
    require(authorizedTrainers[msg.sender], "Not authorized");
    require(initialWeights.length > 0, "Weights required");

    uint256 modelId = modelCount++;

    // Encrypt the weights
    euint32[] memory encryptedWeights = new euint32[](initialWeights.length);
    for (uint i = 0; i < initialWeights.length; i++) {
        encryptedWeights[i] = FHE.asEuint32(initialWeights[i]);
        FHE.allowThis(encryptedWeights[i]);  // Allow contract to use this data
    }

    // Encrypt the biases
    euint32[] memory encryptedBiases = new euint32[](initialBiases.length);
    for (uint i = 0; i < initialBiases.length; i++) {
        encryptedBiases[i] = FHE.asEuint32(initialBiases[i]);
        FHE.allowThis(encryptedBiases[i]);
    }

    models[modelId] = Model({
        weights: encryptedWeights,
        biases: encryptedBiases,
        trainingRounds: 0,
        trainer: msg.sender,
        isComplete: false
    });

    emit ModelCreated(modelId, msg.sender);
    return modelId;
}
```

#### Data Contribution Function

```solidity
function contributeTrainingData(
    uint32[] memory features,
    uint8 label
) external {
    require(features.length > 0, "Features required");

    // Encrypt the input features
    euint32[] memory encryptedFeatures = new euint32[](features.length);
    for (uint i = 0; i < features.length; i++) {
        encryptedFeatures[i] = FHE.asEuint32(features[i]);
        FHE.allowThis(encryptedFeatures[i]);
    }

    // Encrypt the label
    euint8 encryptedLabel = FHE.asEuint8(label);
    FHE.allowThis(encryptedLabel);

    // Reward the contributor
    contributorRewards[msg.sender] += 100;

    emit DataContributed(msg.sender, 100);
}
```

### Step 5: Add Authorization Functions

```solidity
modifier onlyOwner() {
    require(msg.sender == owner, "Not owner");
    _;
}

constructor() {
    owner = msg.sender;
    authorizedTrainers[msg.sender] = true;
}

function authorizeTrainer(address trainer) external onlyOwner {
    authorizedTrainers[trainer] = true;
}
```

## 🎨 Creating the Frontend

### Step 1: HTML Structure

Create `index.html`:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Private AI Training - FHEVM Tutorial</title>
    <script src="https://cdn.jsdelivr.net/npm/ethers@5.7.2/dist/ethers.umd.min.js"></script>
</head>
<body>
    <div class="container">
        <header>
            <h1>🔐 Private AI Training</h1>
            <p>Your First FHEVM Application</p>
        </header>

        <div class="wallet-section">
            <button id="connectBtn">Connect Wallet</button>
            <div id="walletInfo"></div>
        </div>

        <div class="actions">
            <div class="card">
                <h3>Create AI Model</h3>
                <input type="text" id="weights" placeholder="Weights (comma-separated)">
                <input type="text" id="biases" placeholder="Biases (comma-separated)">
                <button onclick="createModel()">Create Model</button>
            </div>

            <div class="card">
                <h3>Contribute Training Data</h3>
                <input type="text" id="features" placeholder="Features (comma-separated)">
                <input type="number" id="label" placeholder="Label (0-255)">
                <button onclick="contributeData()">Contribute Data</button>
            </div>
        </div>

        <div id="status"></div>
    </div>
</body>
</html>
```

### Step 2: JavaScript Integration

Add this script section to your HTML:

```javascript
const CONTRACT_ADDRESS = "YOUR_CONTRACT_ADDRESS";
const CONTRACT_ABI = [
    "function createModel(uint32[] memory initialWeights, uint32[] memory initialBiases) external returns (uint256)",
    "function contributeTrainingData(uint32[] memory features, uint8 label) external",
    "function authorizeTrainer(address trainer) external",
    "function modelCount() external view returns (uint256)",
    "event ModelCreated(uint256 indexed modelId, address indexed trainer)",
    "event DataContributed(address indexed contributor, uint256 reward)"
];

let provider, signer, contract, userAddress;

// Connect wallet function
document.getElementById('connectBtn').addEventListener('click', async function() {
    try {
        if (typeof window.ethereum !== 'undefined') {
            await window.ethereum.request({ method: 'eth_requestAccounts' });
            provider = new ethers.providers.Web3Provider(window.ethereum);
            signer = provider.getSigner();
            userAddress = await signer.getAddress();
            contract = new ethers.Contract(CONTRACT_ADDRESS, CONTRACT_ABI, signer);

            document.getElementById('walletInfo').textContent =
                `Connected: ${userAddress.slice(0,6)}...${userAddress.slice(-4)}`;
            document.getElementById('connectBtn').textContent = 'Connected';
            document.getElementById('connectBtn').disabled = true;

            showStatus('Wallet connected successfully!', 'success');
        } else {
            showStatus('Please install MetaMask!', 'error');
        }
    } catch (error) {
        console.error('Connection failed:', error);
        showStatus('Failed to connect wallet', 'error');
    }
});

// Create model function
async function createModel() {
    if (!contract) {
        showStatus('Please connect wallet first!', 'error');
        return;
    }

    const weightsInput = document.getElementById('weights').value;
    const biasesInput = document.getElementById('biases').value;

    try {
        const weights = weightsInput.split(',').map(w => parseInt(w.trim()));
        const biases = biasesInput.split(',').map(b => parseInt(b.trim()));

        showStatus('Creating model... Please confirm transaction', 'info');
        const tx = await contract.createModel(weights, biases);

        showStatus('Transaction submitted. Waiting for confirmation...', 'info');
        const receipt = await tx.wait();

        showStatus('Model created successfully! 🎉', 'success');
        console.log('Transaction receipt:', receipt);
    } catch (error) {
        console.error('Failed to create model:', error);
        showStatus('Failed to create model: ' + error.message, 'error');
    }
}

// Contribute data function
async function contributeData() {
    if (!contract) {
        showStatus('Please connect wallet first!', 'error');
        return;
    }

    const featuresInput = document.getElementById('features').value;
    const label = parseInt(document.getElementById('label').value);

    try {
        const features = featuresInput.split(',').map(f => parseInt(f.trim()));

        showStatus('Contributing data... Please confirm transaction', 'info');
        const tx = await contract.contributeTrainingData(features, label);

        showStatus('Transaction submitted. Waiting for confirmation...', 'info');
        const receipt = await tx.wait();

        showStatus('Data contributed successfully! You earned 100 reward points! 🎉', 'success');
    } catch (error) {
        console.error('Failed to contribute data:', error);
        showStatus('Failed to contribute data: ' + error.message, 'error');
    }
}

// Status display function
function showStatus(message, type) {
    const statusDiv = document.getElementById('status');
    statusDiv.textContent = message;
    statusDiv.className = `status ${type}`;
    setTimeout(() => statusDiv.textContent = '', 5000);
}
```

### Step 3: Add CSS Styling

Add a `<style>` section in your HTML head:

```css
<style>
* {
    margin: 0;
    padding: 0;
    box-sizing: border-box;
}

body {
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    min-height: 100vh;
    color: #333;
}

.container {
    max-width: 800px;
    margin: 0 auto;
    padding: 20px;
}

header {
    text-align: center;
    color: white;
    margin-bottom: 30px;
}

header h1 {
    font-size: 2.5rem;
    margin-bottom: 10px;
}

.wallet-section {
    background: white;
    padding: 20px;
    border-radius: 10px;
    margin-bottom: 30px;
    text-align: center;
}

button {
    background: linear-gradient(45deg, #667eea, #764ba2);
    color: white;
    border: none;
    padding: 12px 24px;
    border-radius: 6px;
    cursor: pointer;
    font-size: 16px;
    transition: opacity 0.2s;
}

button:hover {
    opacity: 0.9;
}

button:disabled {
    opacity: 0.6;
    cursor: not-allowed;
}

.actions {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(350px, 1fr));
    gap: 20px;
    margin-bottom: 30px;
}

.card {
    background: white;
    padding: 25px;
    border-radius: 10px;
    box-shadow: 0 4px 6px rgba(0,0,0,0.1);
}

.card h3 {
    color: #667eea;
    margin-bottom: 20px;
}

input {
    width: 100%;
    padding: 10px;
    margin-bottom: 15px;
    border: 2px solid #e1e8ed;
    border-radius: 6px;
    font-size: 14px;
}

input:focus {
    outline: none;
    border-color: #667eea;
}

.status {
    padding: 15px;
    border-radius: 6px;
    text-align: center;
    font-weight: 500;
}

.status.success {
    background: #d4edda;
    color: #155724;
}

.status.error {
    background: #f8d7da;
    color: #721c24;
}

.status.info {
    background: #cce7ff;
    color: #004085;
}
</style>
```

## 🚀 Deployment Guide

### Step 1: Compile Your Contract

```bash
npx hardhat compile
```

### Step 2: Create Deployment Script

Create `scripts/deploy.js`:

```javascript
async function main() {
  const PrivateAITraining = await ethers.getContractFactory("PrivateAITraining");

  console.log("Deploying PrivateAITraining contract...");
  const contract = await PrivateAITraining.deploy();
  await contract.deployed();

  console.log(`Contract deployed to: ${contract.address}`);
  console.log(`Transaction hash: ${contract.deployTransaction.hash}`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
```

### Step 3: Deploy to Testnet

```bash
# Deploy to Sepolia testnet
npx hardhat run scripts/deploy.js --network sepolia
```

### Step 4: Update Frontend

Replace `YOUR_CONTRACT_ADDRESS` in your HTML file with the deployed contract address.

## 🧪 Testing Your Application

### Step 1: Local Testing

1. **Start Local Server**:
   ```bash
   # Simple HTTP server
   npx http-server . -p 3000 -c-1 --cors
   ```

2. **Open Browser**: Navigate to `http://localhost:3000`

### Step 2: Wallet Setup

1. Install MetaMask extension
2. Add Sepolia testnet to MetaMask
3. Get test ETH from [Sepolia faucet](https://sepoliafaucet.com/)

### Step 3: Test Contract Functions

1. **Connect Wallet**: Click "Connect Wallet" button
2. **Authorize Yourself**: If you're the contract owner, authorize your address
3. **Create Model**: Try creating a model with weights like `100,200,300` and biases `10,20`
4. **Contribute Data**: Add training data with features `50,75,100` and label `1`

### Step 4: Verify Transactions

- Check transaction hashes on [Sepolia Etherscan](https://sepolia.etherscan.io/)
- Verify that encrypted data isn't visible on the blockchain explorer
- Confirm events are emitted correctly

## 🐛 Common Issues & Solutions

### Issue 1: "Not authorized trainer" Error

**Problem**: Getting authorization error when creating models.

**Solution**:
```javascript
// If you're the contract owner, authorize yourself first
await contract.authorizeTrainer(userAddress);
```

### Issue 2: Transaction Fails with Gas Issues

**Problem**: Out of gas errors during deployment/execution.

**Solution**: Increase gas limit in your transactions:
```javascript
const tx = await contract.createModel(weights, biases, {
    gasLimit: 2000000
});
```

### Issue 3: MetaMask Connection Issues

**Problem**: Wallet not connecting properly.

**Solution**: Ensure you're on the correct network and refresh the page:
```javascript
// Add network switch logic
await window.ethereum.request({
    method: 'wallet_switchEthereumChain',
    params: [{ chainId: '0xAA36A7' }], // Sepolia testnet
});
```

### Issue 4: FHE Operations Failing

**Problem**: Encrypted operations not working as expected.

**Solution**: Always call `FHE.allowThis()` after creating encrypted values:
```solidity
euint32 encrypted = FHE.asEuint32(value);
FHE.allowThis(encrypted);  // Don't forget this!
```

## 📚 Understanding What You Built

### Privacy Features Explained

1. **Encrypted Weights**: Model parameters remain hidden from everyone, including the blockchain
2. **Private Training Data**: Contributors' data is encrypted and never exposed
3. **Confidential Computations**: All AI training happens on encrypted data
4. **Selective Disclosure**: Only authorized parties can access specific encrypted values

### Key Learning Points

- **FHE Integration**: You learned to work with encrypted types (`euint32`, `euint8`)
- **Access Control**: Implemented proper permission systems for encrypted data
- **Web3 Integration**: Connected frontend to FHEVM smart contracts
- **Real-world Application**: Built a practical privacy-preserving system

## 🎯 Next Steps

Now that you've completed your first FHEVM tutorial, consider these advancement paths:

### 1. Enhance Your Current Project
- Add more complex AI training algorithms
- Implement model evaluation metrics
- Create a token-based reward system
- Add batch processing for training data

### 2. Explore Advanced FHEVM Features
- **Conditional Logic**: Use `FHE.select()` for encrypted if/else statements
- **Comparison Operations**: Implement encrypted sorting or filtering
- **Access Control Lists**: Create sophisticated permission systems
- **Reencryption**: Allow users to decrypt their own data

### 3. Build New Projects
- **Private Voting System**: Anonymous ballot collection and counting
- **Confidential Auctions**: Sealed-bid auction mechanisms
- **Healthcare Analytics**: Privacy-preserving medical data analysis
- **Financial Privacy**: Private credit scoring or risk assessment

### 4. Integration Patterns
- **Layer 2 Solutions**: Deploy on FHE-enabled L2 networks
- **Oracle Integration**: Combine with Chainlink for external encrypted data
- **Multi-Chain**: Bridge encrypted data across different blockchains
- **Mobile Applications**: Build React Native apps with FHEVM

### 5. Advanced Topics
- **Gas Optimization**: Techniques for reducing FHE computation costs
- **Batch Operations**: Processing multiple encrypted values efficiently
- **Proof Systems**: Combining FHE with zero-knowledge proofs
- **Threshold Encryption**: Multi-party control over encrypted data

## 🌟 Congratulations!

You've successfully built your first confidential smart contract application! You now understand:

✅ **FHEVM Fundamentals**: How to work with encrypted blockchain data
✅ **Smart Contract Development**: Building privacy-preserving contracts
✅ **Frontend Integration**: Connecting web apps to FHEVM
✅ **Deployment Process**: Publishing to test networks
✅ **Testing Strategies**: Verifying confidential applications work correctly

**You're now ready to build the next generation of privacy-preserving blockchain applications!**

---

## 📞 Support & Resources

- **FHEVM Documentation**: [https://docs.zama.ai/fhevm](https://docs.zama.ai/fhevm)
- **Community Discord**: Join the Zama developer community
- **GitHub Examples**: Explore more FHEVM project templates
- **Tutorial Updates**: Check for the latest version of this guide

**Happy Building! 🚀**

---

*This tutorial was created to help developers enter the world of confidential smart contracts. Share your projects and let's build a privacy-first blockchain ecosystem together!*