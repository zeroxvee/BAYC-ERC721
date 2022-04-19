// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/**
 * @title BAYC contract recreated for learning/testing purposes by using
 * openzeppelin contract wizard and a minimum of changes
 */
contract SuperFakeBoredApeYachtClub is ERC721, ERC721Enumerable, Pausable, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    // Minting price per token
    uint256 private mintPrice;
    // Max amount to mint per transaction
    uint256 private maxMintPerTx;
    // URI of the collection
    string private uri;

    string constant private NAME = "SuperFakeBoredApeYachtClub";
    string constant private SYMBOL = "SFBAYC";
    // Max possible token supply
    uint256 constant public MAX_SUPPLY = 10_000;

    constructor(uint256 _mintPrice, uint256 _maxMintPerTx, string memory _uri) ERC721(NAME, SYMBOL) {
        mintPrice = _mintPrice;
        maxMintPerTx = _maxMintPerTx;
        uri = _uri;
    }

    
    /**
     * @notice Returns the URI of the collection
     * @return uri as string
     */
    function _baseURI() internal view override returns (string memory) {
        return uri;
    }

    function setURI(string memory _uri) external onlyOwner() {
        uri = _uri;
    }

    // Pause contract
    function pause() public onlyOwner {
        _pause();
    }

    // Unpause contract
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @notice Mint ape tokens
     * @param _tokenAmount amount of token to mint
     */
    function mintApe(uint256 _tokenAmount) public payable whenNotPaused() {
        uint price = mintPrice * _tokenAmount;
        require(msg.value >= price, "Not enough ether to mint");
        require(_tokenAmount <= maxMintPerTx && _tokenAmount > 0, "Can be from 1 to 20");
        require(totalSupply() + _tokenAmount <= MAX_SUPPLY, "Total ape supply reached");

        for (uint i = 0; i < _tokenAmount; i++) {
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            _mint(msg.sender, tokenId);
        }

        // Send refund back if buyer not using web to mint.
        uint256 refund = msg.value - price;
        if (refund > 0) {
            payable(msg.sender).transfer(refund);
        }
    }

    /**
     * @notice Chnage the price of minting
     * @param _mintPrice New token mint price
     */
    function changeMintPrice(uint256 _mintPrice) external onlyOwner() whenPaused() {
        mintPrice = _mintPrice;
    }

    // Withdraw all ether from the contract
    function withdrawAll() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No ether to withdraw");
        payable(msg.sender).transfer(balance);
    }

    //A required function override by the OpenZeppelin library
    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // Check if the contract supports interface
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
