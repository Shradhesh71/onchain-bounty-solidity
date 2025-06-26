const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("BountyNFT", function () {
  it("should mint NFT with correct URI", async () => {
    const [owner, user] = await ethers.getSigners();
    const NFT = await ethers.getContractFactory("BountyNFT");
    const nft = await NFT.deploy();
    await nft.deployed();

    await nft.transferOwnership(owner.address);
    await nft.mint(user.address, "ipfs://test123");

    expect(await nft.ownerOf(1)).to.equal(user.address);
    expect(await nft.tokenURI(1)).to.equal("ipfs://test123");
  });
});
