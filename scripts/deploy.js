// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const { expect } = require('chai');
const { ethers,run } = require('hardhat');
async function main() {
  const [deployer] = await ethers.getSigners();
  //Deploy SpaceRoomManager
  const spaceRoomManager = await ethers.getContractFactory("SpaceRoomManager");
  const spaceRoomManagerContract = await spaceRoomManager.deploy(deployer.address);
  console.log("wait for deployment")
  await spaceRoomManagerContract.waitForDeployment(30);
  const spaceroomAddress = await spaceRoomManagerContract.getAddress();
  console.log("SupplyChain deployed to:",spaceroomAddress);

  //Deploy VotingManager
  const votingManager = await ethers.getContractFactory("VotingManager");
  const votingManagerContract = await votingManager.deploy(spaceroomAddress);
  console.log("wait for deployment")
  await votingManagerContract.waitForDeployment(30);
  const votingAddress = await votingManagerContract.getAddress();
  console.log("VotingManager deployed to:", votingAddress);

  
}
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
