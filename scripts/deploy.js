const { ethers } = require("hardhat");


async function main() {
  console.log("Deploying DecentraDocs contract to Core Blockchain...");

  // Get the contract factory
  const DecentraDocs = await ethers.getContractFactory("DecentraDocs");

  // Deploy the contract (no constructor parameters needed)
  const decentraDocs = await DecentraDocs.deploy();

  // Wait for deployment to complete
  await decentraDocs.deployed();

  console.log("DecentraDocs deployed to:", decentraDocs.address);
  console.log("Transaction hash:", decentraDocs.deployTransaction.hash);

  // Verify deployment
  console.log("Verifying deployment...");
  const code = await ethers.provider.getCode(decentraDocs.address);
  if (code === "0x") {
    console.log("❌ Contract deployment failed!");
  } else {
    console.log("✅ Contract deployed successfully!");
    console.log("Contract address:", decentraDocs.address);
    console.log("Network: Core Testnet");
    console.log("Block number:", decentraDocs.deployTransaction.blockNumber);

    // Display initial contract state
    const storageFee = await decentraDocs.storageFee();
    console.log(
      "Initial storage fee:",
      ethers.utils.formatEther(storageFee),
      "CORE"
    );
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("Deployment failed:", error);
    process.exit(1);
  });
