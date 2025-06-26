# On-Chain Bounty Board Smart Contracts

This repository contains the on-chain Solidity contracts for the On-Chain Bounty Board hackathon project. It includes the core `BountyAgent` contract for managing bounties and the `BountyNFT` contract for minting proof-of-completion NFTs.

---

## 📦 Contracts

- **BountyAgent.sol**

  - Manages creation of bounties, entry-fee submissions, prize distribution, refunds, and cancellations.
  - Uses SafeERC20 for secure USDC transfers and ReentrancyGuard for safety.
  - Tracks submission fees and automates refunds/burns.
  - Emits events: `BountyCreated`, `SubmissionPaid`, `PrizesDistributed`, `BountyCanceled`, `PlatformFeeUpdated`.

- **BountyNFT.sol**

  - ERC-721 token that mints a unique NFT to each winner as proof of completion.
  - Access-controlled minting via a configurable `minter` address.

---

## 🛠️ Prerequisites

- **Node.js & npm** (for scripts)
- **Hardhat** (or Truffle) for compilation, testing, and deployment
- **Sepolia testnet** (or your chosen network)

---

## ⚙️ Setup & Install

1. **Clone the repo**

   ```bash
   git clone https://github.com/your-org/bounty-contracts.git
   cd bounty-contracts
   ```

2. **Install dependencies**

   ```bash
   npm install
   ```

3. **Configure environment**

   - Create a `.env` file:

     ```env
     RPC_URL_SEPOLIA=https://sepolia.infura.io/v3/YOUR_INFURA_KEY
     DEPLOYER_PRIVATE_KEY=YOUR_PRIVATE_KEY
     ```

---

## 🚀 Compilation & Tests

- **Compile**

  ```bash
  npx hardhat compile
  ```

- **Run tests**

  ```bash
  npx hardhat test
  ```

---

## 📤 Deployment

1. **Deploy to Sepolia**

   ```bash
   npx hardhat run --network sepolia scripts/deploy.js
   ```

2. **Verify on Etherscan**

   ```bash
   npx hardhat verify --network sepolia <DEPLOYED_CONTRACT_ADDRESS> <constructor_args>
   ```

---

## 🔍 Contract Details

### BountyAgent.sol

```solidity
constructor(address _nftAddress, address _usdcAddress)
```

- **\_nftAddress**: Address of deployed `BountyNFT` contract.
- **\_usdcAddress**: USDC token contract address (Sepolia).

#### Key Functions

- `createBounty(prize, entryFee, maxWinners, deadline, topic, description)`

  - Requires ERC-20 allowance and deposit of prize into contract.

- `submitWork(bountyId, cid)`

  - Collects entry fee, stores IPFS CID per submission.

- `distributePrizes(bountyId, winnerIndexes[])`

  - Transfers platform fee to owner, pays winners, mints NFTs, refunds non-winners.

- `cancelBounty(bountyId)`

  - Allows creator to cancel before deadline and reclaim prize.

- `setPlatformFee(bps)`

  - Owner can adjust fee (max 10%).

### BountyNFT.sol

```solidity
function setMinter(address _minter) external onlyOwner;
function mint(address to, string memory metadataURI) external;
```

- **setMinter**: Grants minting rights to the agent contract.
- **mint**: Mints a new token with given metadata URI.

---

## ✅ Security & Audits

- **SafeERC20** ensures compatibility with non-standard ERC-20 tokens.
- **ReentrancyGuard** protects against reentrancy attacks.
- Comprehensive unit tests cover edge cases (zero submissions, duplicate entries, out-of-bounds winners).

---

## 📄 License

This project is licensed under the **MIT License**. See [LICENSE](LICENSE) for details.
