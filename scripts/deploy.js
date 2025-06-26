const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying contracts with:", deployer.address);

  // USDC address on Sepolia testnet
  const usdcAddress = "0x9f582979470b73C72F2EA7465F0A3c17Fc582D9f";
  console.log("Using USDC at:", usdcAddress);

  // Deploy BountyNFT
  const BountyNFT = await hre.ethers.getContractFactory("BountyNFT");
  const nft = await BountyNFT.deploy();
  await nft.waitForDeployment();
  const nftAddress = await nft.getAddress();
  console.log("BountyNFT deployed at:", nftAddress);

  // Deploy BountyAgent with both nftAddress and usdcAddress
  const BountyAgent = await hre.ethers.getContractFactory("BountyAgent");
  const agent = await BountyAgent.deploy(nftAddress, usdcAddress);
  await agent.waitForDeployment();
  const agentAddress = await agent.getAddress();
  console.log("BountyAgent deployed at:", agentAddress);

  // Transfer ownership of BountyNFT to BountyAgent
  const tx = await nft.transferOwnership(agentAddress);
  await tx.wait();
  console.log("NFT ownership transferred to BountyAgent.");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });