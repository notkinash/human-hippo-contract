// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract LosCubs is ERC721Enumerable, ERC721Pausable, ERC721Burnable, ReentrancyGuard, Ownable {
    using Counters for Counters.Counter;
    
    using Strings for uint256;

    uint256 public constant maxSupply = 111;

    uint256 public constant bearsToBurn = 2;

    uint256 public constant honeysToBurn = 10;

    uint256 public mintPrice = 100 ether;

    string public defaultBaseURI;

    Counters.Counter private _tokenIds;

    constructor(string memory metadataURI) ERC721("Los Cubs", "CUBS") {
        defaultBaseURI = metadataURI;
        _tokenIds.increment();
    }

    function mint(uint256 quantity) external payable whenNotPaused {
        require(msg.value >= (mintPrice * quantity), "Invalid amount");
        uint256 tokenId = _tokenIds.current();
        require((tokenId + quantity - 1) < maxSupply, "Mint limit reached");
        for (uint256 i = 0; i < quantity; i++) {
            _mint(msg.sender, tokenId + i);
            _tokenIds.increment();
        }
    }

    function give(address to, uint256 quantity) external onlyOwner {
        uint256 tokenId = _tokenIds.current();
        require((tokenId + quantity - 1) < maxSupply, "Mint limit reached");
        for (uint256 i = 0; i < quantity; i++) {
            _safeMint(to, tokenId + i);
            _tokenIds.increment();
        }
    }

    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Withdraw failed");
    }

    function togglePause() external onlyOwner {
        if (paused()) {
            _unpause();
        } else {
            _pause();
        }
    }

    function setMintPrice(uint256 newPrice) external onlyOwner {
        mintPrice = newPrice;
    }

    function setBaseURI(string calldata newURI) external onlyOwner {
        defaultBaseURI = newURI;
    }

    function _baseURI() internal view override(ERC721) returns (string memory) {
        return defaultBaseURI;
    }

    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        return string(abi.encodePacked(_baseURI(), tokenId.toString(), ".json"));
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override(ERC721, ERC721Enumerable, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
        require(!paused(), "token transfer while paused");
    }
}