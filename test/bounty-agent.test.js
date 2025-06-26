const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("BountyAgent", function () {
  let bountyAgent, bountyNFT;
  let creator, contributor1, contributor2;

  beforeEach(async () => {
    [creator, contributor1, contributor2, _] = await ethers.getSigners();

    const NFT = await ethers.getContractFactory("BountyNFT");
    bountyNFT = await NFT.deploy();
    await bountyNFT.deployed();

    const Agent = await ethers.getContractFactory("BountyAgent");
    bountyAgent = await Agent.deploy(bountyNFT.address);
    await bountyAgent.deployed();

    // Transfer ownership of NFT contract to Agent so it can mint
    await bountyNFT.transferOwnership(bountyAgent.address);
  });

  it("should create a bounty", async () => {
    await expect(
      bountyAgent.connect(creator).createBounty(
        ethers.utils.parseEther("0.01"), // entry fee
        2, // max winners
        (await ethers.provider.getBlock("latest")).timestamp + 1000,
        { value: ethers.utils.parseEther("1.0") } // bounty prize
      )
    ).to.emit(bountyAgent, "BountyCreated");
  });

  it("should allow users to submit work", async () => {
    // Create bounty
    await bountyAgent.connect(creator).createBounty(
      ethers.utils.parseEther("0.01"),
      2,
      (await ethers.provider.getBlock("latest")).timestamp + 1000,
      { value: ethers.utils.parseEther("1.0") }
    );

    await expect(
      bountyAgent.connect(contributor1).submitWork(1, "cid1", {
        value: ethers.utils.parseEther("0.01"),
      })
    ).to.emit(bountyAgent, "SubmissionPaid");

    await expect(
      bountyAgent.connect(contributor2).submitWork(1, "cid2", {
        value: ethers.utils.parseEther("0.01"),
      })
    ).to.emit(bountyAgent, "SubmissionPaid");
  });

  it("should distribute prizes and mint NFTs", async () => {
    // Create bounty
    await bountyAgent.connect(creator).createBounty(
      ethers.utils.parseEther("0.01"),
      2,
      (await ethers.provider.getBlock("latest")).timestamp + 1, // short deadline
      { value: ethers.utils.parseEther("1.0") }
    );

    await bountyAgent.connect(contributor1).submitWork(1, "cid1", {
      value: ethers.utils.parseEther("0.01"),
    });

    await bountyAgent.connect(contributor2).submitWork(1, "cid2", {
      value: ethers.utils.parseEther("0.01"),
    });

    // Wait until deadline
    await ethers.provider.send("evm_increaseTime", [2]);
    await ethers.provider.send("evm_mine");

    await expect(
      bountyAgent.connect(creator).distributePrizes(1, [0, 1])
    ).to.emit(bountyAgent, "PrizesDistributed");

    expect(await bountyNFT.ownerOf(1)).to.equal(contributor1.address);
    expect(await bountyNFT.ownerOf(2)).to.equal(contributor2.address);
  });
});
