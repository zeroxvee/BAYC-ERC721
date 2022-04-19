// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

/**
 * Abstract contract for MAYC to utilize BACC contract functions
 */
abstract contract Bacc {
    function burnSerumForAddress(uint256 typeId, address burnTokenAddress)
        external
        virtual;

    function balanceOf(address account, uint256 id)
        public
        view
        virtual
        returns (uint256);
}