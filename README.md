# core-contract

The repository contains smart contracts and deployment scripts that facilitate content creation and voting management systems. It's implemented using Hardhat as the primary development environment.

## Project Structure

- `contracts/`: Contains Solidity source files for the contracts.

  - `SpaceRoomManager.sol`: Manages spaces/rooms where creators can publish content.
  - `VotingManager.sol`: Manages voting processes related to the content.
- `node_modules/`: Installed Node.js modules required for development.
- `scripts/`: JavaScript deployment scripts.

  - `deploy.js`: Script to deploy SpaceRoomManager and VotingManager contracts.
- `test/`: Tests for the contracts.

  - `SpaceRoomManager.js`: Testing file for the SpaceRoomManager contract.
- `ex.env`: Example environment variables template.
- `hardhat.config.js`: Configuration file for Hardhat.
- `package.json`: Project metadata and dependency manager.
- `README.md`: Documentation file.

## Prerequisites

Ensure you have these tools installed before using this project:

- Node.js (v18 or higher)
- NPM (comes with Node.js)

## Installation

1. **Clone the Repository:**Clone the project repository and navigate into its folder.

   ```bash
   git clone https://github.com/your-repo/core-contract.git
   cd core-contract
   ```
2. **Install Dependencies:**Install the required Node.js packages.

   ```bash
   npm install
   ```
3. **Configure Environment Variables:**
   Create a `.env` file in the project's root directory using `ex.env` as a template. Populate it with the necessary variables:

   INFURA_API_KEY=your-infura-api-key //or another provider
   PRIVATE_KEY=your-private-key
   ETHERSCAN_API_KEY=your-etherscan-api-key
4. **Configure Network in `hardhat.config.ts`:**
   Set up the network settings to enable deployment to different networks

## Usage

1. **Compile the Contracts:**Use Hardhat to compile the contracts.

   ```bash
   npx hardhat compile
   ```
2. **Deploy Contracts:**Run the deployment script to deploy both SpaceRoomManager and VotingManager contracts. Specify the network by replacing `your_network` with the desired one.

   ```bash
   npx hardhat run scripts/deploy.js --network your_network
   ```

   The deployed contract addresses will be printed to the console and saved in the `deployedContract.txt` file.
3. **Testing:**
   Run the test files to validate the functionality of the contracts:

   ```bash
   npx hardhat test
   ```

## Troubleshooting

- Verify that your environment variables are correctly set up.
- Confirm that Node.js, NPM, and Hardhat are correctly installed.
- Ensure the required dependencies are installed using `npm install`.

## License

This project is licensed under the MIT License.
