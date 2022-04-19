// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

/**
 * Abstract contract for MAYC to utilize BAYC contract functions
 */
abstract contract Bayc {
    function ownerOf(uint256 tokenId) public view virtual returns (address);
}