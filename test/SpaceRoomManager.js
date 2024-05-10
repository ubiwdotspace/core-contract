// SupplyChain.test.js
const { expect } = require('chai');
const { ethers } = require('hardhat');
const {
  loadFixture,
} = require("@nomicfoundation/hardhat-toolbox/network-helpers");
describe("Test Unit", function () {
  async function deployFixture() {
    let [owner,authorized,newOwner,random] = await ethers.getSigners();
    const supplyChain = await ethers.deployContract("SpaceRoomManager", [owner.address]);
    console.log("SpaceRoomManager deployed to:", await supplyChain.getAddress());
    console.log("Owner address:", await owner.getAddress());
    
  };
  it("should deploy", async function () {
    await deployFixture();
  });
  
});
