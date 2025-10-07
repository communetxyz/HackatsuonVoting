# Hackathon Voting Smart Contract

A transparent, blockchain-based voting system for hackathon projects built with Solidity and Foundry.

## Features

- **Transparent Voting**: All votes are publicly verifiable on blockchain
- **Two Votes Per Address**: Each address can vote for up to 2 different projects
- **On-chain Resolution**: Trustless winner determination
- **Comprehensive View Function**: All frontend data in one call
- **Gas Efficient**: Optimized for Gnosis Chain deployment

## Contract Overview

### Main Functions

#### Admin Functions (Owner Only)
- `registerProject()`: Register a new project for voting
- `resolveVoting()`: Finalize voting and determine the winner

#### User Functions
- `vote(uint256 projectId)`: Cast a vote for a project (max 2 votes per address)
- `getMyVotes()`: Get the projects you've voted for

#### View Functions
- `getVotingData(address viewer)`: Get all voting data in a single call
- `getProject(uint256 projectId)`: Get details of a specific project
- `getTotalVotes()`: Get total number of votes cast

## Installation

```bash
# Install Foundry (if not already installed)
curl -L https://foundry.paradigm.xyz | bash
foundryup

# Install dependencies
forge install
```

## Build

```bash
forge build
```

## Test

```bash
# Run all tests
forge test

# Run tests with verbosity
forge test -vv

# Run tests with gas reporting
forge test --gas-report

# Run specific test
forge test --match-test test_Vote
```

## CI/CD

This project includes GitHub Actions workflows for automated testing and deployment:

### Workflows

1. **CI Tests** (`.github/workflows/tests.yml`)
   - Runs on every push
   - Executes unit tests
   - Generates gas reports
   - Checks code formatting

2. **Testnet Deployment** (`.github/workflows/deploy-testnet.yml`)
   - Deploys to Holesky testnet
   - Triggers on PRs and pushes to main
   - Verifies contract on Etherscan
   - Posts deployment info as PR comment

3. **Mainnet Deployment** (`.github/workflows/deploy-gnosis.yml`)
   - Deploys to Gnosis Chain mainnet
   - Triggers on main branch pushes and releases
   - Verifies contract on GnosisScan
   - Runs test transactions
   - Creates GitHub releases with deployment artifacts

### Required Secrets

Configure these secrets in your GitHub repository settings:

**For Testnet (Holesky):**
- `TESTNET_PRIVATE_KEY`: Private key for testnet deployment
- `ETHERSCAN_API_KEY`: Etherscan API key for contract verification

**For Mainnet (Gnosis Chain):**
- `GNOSIS_PRIVATE_KEY`: Private key for mainnet deployment
- `GNOSISSCAN_API_KEY`: GnosisScan API key for contract verification

### Manual Deployment

To manually trigger a deployment:

1. Go to **Actions** tab in your GitHub repository
2. Select the workflow (testnet or mainnet)
3. Click **Run workflow**
4. Configure options (e.g., verification, release creation)

## Deployment

### Local Deployment (Anvil)

```bash
# Start local node
anvil

# Deploy to local node
forge script script/Deploy.s.sol:DeployScript --rpc-url http://localhost:8545 --broadcast
```

### Gnosis Chain Deployment

1. Copy `.env.example` to `.env` and fill in your credentials:
```bash
cp .env.example .env
```

2. Deploy to Gnosis Chain:
```bash
source .env
forge script script/Deploy.s.sol:DeployScript \
  --rpc-url $GNOSIS_RPC_URL \
  --broadcast \
  --verify
```

### Testnet Deployment (Holesky)

```bash
forge script script/Deploy.s.sol:DeployScript \
  --rpc-url https://ethereum-holesky-rpc.publicnode.com \
  --broadcast
```

## Verification

To verify the contract on GnosisScan after deployment:

```bash
forge verify-contract \
  --chain-id 100 \
  --compiler-version v0.8.20 \
  <CONTRACT_ADDRESS> \
  src/HackathonVoting.sol:HackathonVoting \
  --etherscan-api-key $GNOSISSCAN_API_KEY
```

## Contract Interaction Examples

### Using Cast (Foundry CLI)

```bash
# Register a project (owner only)
cast send <CONTRACT_ADDRESS> \
  "registerProject(string,string,string,uint8,string,string,string)" \
  "AI Project" \
  "An AI-powered solution" \
  "Team A" \
  0 \
  "https://image.url" \
  "https://demo.url" \
  "https://github.url" \
  --rpc-url $GNOSIS_RPC_URL \
  --private-key $PRIVATE_KEY

# Vote for a project
cast send <CONTRACT_ADDRESS> \
  "vote(uint256)" \
  1 \
  --rpc-url $GNOSIS_RPC_URL \
  --private-key $PRIVATE_KEY

# Get voting data
cast call <CONTRACT_ADDRESS> \
  "getVotingData(address)" \
  <VIEWER_ADDRESS> \
  --rpc-url $GNOSIS_RPC_URL

# Resolve voting (owner only)
cast send <CONTRACT_ADDRESS> \
  "resolveVoting()" \
  --rpc-url $GNOSIS_RPC_URL \
  --private-key $PRIVATE_KEY
```

## Architecture

### Categories

The contract supports four project categories:
- AI
- Web3
- IoT
- Other

### Voting Rules

- Each address can vote for up to 2 different projects
- Voters are NOT required to use both votes
- Both votes have equal weight (1 vote = 1 vote)
- Cannot vote twice for the same project
- Votes cannot be changed once submitted
- Voting stops once resolved by admin

### Data Structures

#### Project
```solidity
struct Project {
    uint256 id;
    string title;
    string description;
    string teamName;
    Category category;
    string imageUrl;
    string demoUrl;
    string githubUrl;
    uint256 voteCount;
    address submitter;
}
```

#### VotingData
```solidity
struct VotingData {
    ProjectInfo[] projects;
    uint256 totalVotes;
    uint256 totalVoters;
    uint256[] voterProjectIds;
    bool votingResolved;
    uint256 winnerProjectId;
    CategoryStats[] categoryVotes;
}
```

## Gas Optimization

The contract is optimized for gas efficiency:
- Uses custom errors instead of require strings
- Implements ReentrancyGuard for security
- Efficient storage layout
- Single view function reduces RPC calls

## Security

- **Ownable**: Admin functions protected by OpenZeppelin's Ownable
- **ReentrancyGuard**: Vote function protected against reentrancy attacks
- **Input Validation**: All inputs validated with custom errors
- **Immutable Votes**: Votes cannot be changed once cast

## License

MIT
