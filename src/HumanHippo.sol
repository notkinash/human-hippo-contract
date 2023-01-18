// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./ILosCubs.sol";

contract HumanHippo is ERC721Enumerable, ERC721Pausable, ERC721Royalty, ReentrancyGuard, Ownable {
    uint256 private _tokenIds;

    uint256 private _firstTokenId;

    uint256 public mintPrice;

    // Limits

    uint256 public collectionSize;

    // Controls

    bool public mintAvailable;

    bool public publicSale;

    uint256 public publicSaleStart;

    uint256 public publicSaleDifference;

    string private _defaultBaseURI;

    // Whitelist

    ILosCubs private _losCubs;

    mapping(address => bool) public whitelist;
    
    constructor(
        uint256 _startTokenId,
        uint256 _mintPrice,
        uint256 _collectionSize,
        address _royaltiesReceiver,
        uint96 _royaltiesFraction,
        uint256 _publicSaleDifference,
        string memory _metadataURI,
        address _losCubsAddress
    ) ERC721("Human Hippo", "HIPPO") {
        _tokenIds = _startTokenId;
        _firstTokenId = _startTokenId;
        mintPrice = _mintPrice;
        collectionSize = _collectionSize;
        publicSaleDifference = _publicSaleDifference;
        _defaultBaseURI = _metadataURI;
        _losCubs = ILosCubs(_losCubsAddress);
        _setDefaultRoyalty(_royaltiesReceiver, _royaltiesFraction);
    }

    // Mint functions

    function mint(uint256 quantity) external payable whenNotPaused {
        // Check if mint is available
        require(mintAvailable, "Mint isn't available yet");

        if (!publicSale && publicSaleStart != 0) {
            if (block.timestamp >= publicSaleStart) {
                publicSale = true;
            }
        }

        // Check if minter is whitelisted or is public sale
        require(whitelisted(msg.sender) || publicSale, "Sale not available");

        // Check if there is enough tokens available
        uint256 nextTotalMinted = (_tokenIds - _firstTokenId) + quantity;
        require(nextTotalMinted <= collectionSize, "Sold out");

        // Check if minter is paying the correct price
        uint256 price = quantity * mintPrice;
        require(msg.value == price, "Wrong price given");

        for (uint256 i = 0; i < quantity; i++) {
            _mint(msg.sender, _tokenIds++);
        }
    }

    function give(address to, uint256 quantity) external onlyOwner whenNotPaused {
        // Check if there is enough tokens available
        uint256 nextTotalMinted = (_tokenIds - _firstTokenId) + quantity;
        require(nextTotalMinted <= collectionSize, "Sold out");

        for (uint256 i = 0; i < quantity; i++) {
            _mint(to, _tokenIds++);
        }
    }

    // Whitelist functions

    function whitelisted(address target) public view returns (bool) {
        return _losCubs.balanceOf(target) > 0 || whitelist[target];
    }

    function whitelistAdd(address target) external onlyOwner {
        whitelist[target] = true;
    }

    function whitelistAdd(address[] memory targets) external onlyOwner {
        for (uint256 i = 0; i < targets.length; i++) {
            whitelist[targets[i]] = true;
        }
    }

    function whitelistRemove(address target) external onlyOwner {
        whitelist[target] = false;
    }

    // Control functions

    function toggleMint() external onlyOwner {
        mintAvailable = !mintAvailable;
    }

    function togglePause() external onlyOwner {
        paused() ? _unpause() : _pause();
    }

    function togglePublicSale() external onlyOwner {
        publicSaleStart = block.timestamp + publicSaleDifference;
    }

    function forcePublicSale() external onlyOwner {
        publicSale = !publicSale;
    }

    function setMintPrice(uint256 newPrice) external onlyOwner {
        mintPrice = newPrice;
    }

    function setCollectionSize(uint256 newSize) external onlyOwner {
        collectionSize = newSize;
    }

    function setBaseURI(string calldata newURI) external onlyOwner {
        _defaultBaseURI = newURI;
    }

    function setLosCubs(address newAddress) external onlyOwner {
        _losCubs = ILosCubs(newAddress);
    }

    function setPublicSaleStart(uint256 newTimestamp) external onlyOwner {
        publicSaleStart = newTimestamp;
    }

    // Special functions

    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success, "Withdraw failed");
    }

    // Override functions

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal override(ERC721, ERC721Enumerable, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721Royalty) {
        super._burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable, ERC721Royalty) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        return string(abi.encodePacked(_defaultBaseURI, Strings.toString(tokenId), ".json"));
    }
}