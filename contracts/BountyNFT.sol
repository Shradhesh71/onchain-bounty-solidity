// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract BountyNFT is ERC721URIStorage, Ownable {
    uint256 public tokenCounter;
    address public minter;

    constructor() ERC721("BountyNFT", "BNTSJ") Ownable(msg.sender) {
        minter = msg.sender;
    }

    function setMinter(address _minter) external onlyOwner {
        minter = _minter;
    }

    function mint(address to, string memory metadataURI) external {
        require(msg.sender == minter, "Only minter");
        tokenCounter++;
        _safeMint(to, tokenCounter);
        _setTokenURI(tokenCounter, metadataURI);
    }
}
