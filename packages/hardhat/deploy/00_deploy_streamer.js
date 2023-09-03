// deploy/00_deploy_streamer.js

const { ethers } = require("hardhat");
require("dotenv").config()
const { verify } = require("../utils/verify")

module.exports = async ({ getNamedAccounts, deployments, getChainId }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  await deploy("Streamer", {
    // Learn more about args here: https://www.npmjs.com/package/hardhat-deploy#deploymentsdeploy
    from: deployer,
    log: true,
  });

  const streamer = await ethers.getContract("Streamer", deployer);

  console.log("\n 🤹  Sending ownership to frontend address...\n");
  //Checkpoint 2: change address to your frontend address vvvv
  const ownerTx = await streamer.transferOwnership("0x7988Eff919A23bae1133e44FEAB5D9AD4F99d774");

  console.log("\n       confirming...\n");
  const ownershipResult = await ownerTx.wait();
  if (ownershipResult) {
    console.log("       ✅ ownership transferred successfully!\n");
  }

  if (chainId === 11155111 && process.env.ETHERSCAN_API_KEY) {
    await verify(streamer.address, [])
}
};

module.exports.tags = ["Streamer"];
