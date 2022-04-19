// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Dutch Auction
 * @author @vbazhutin
 * @dev Simple implementation of Dutch Auction, only manages the current price
 * and the sale state of auction. Developed for MAYC contract.
 */
contract DutchAuction is Ownable {
    uint256 private duration;
    uint256 private startingPrice;
    uint256 private saleStartTime;
    uint256 private finalPrice;
    bool isSaleActive = false;

    /**
     * @dev emitted anytime a new sale goes active
     */
    event NewSale(uint256 duration, uint256 startingPrice, uint256 finalPrice, uint256 startTime);

    /**
     * @dev emitted anytime a sale is stopped
     */
    event StopCurrentSale(uint256 stopTime, uint256 finalPrice);

    /**
     * @notice modifier that checks if sale is active
     */
    modifier whenSaleIsActive() {
        require(isSaleActive, "Sale is not active");
        _;
    }

    /**
     * @notice this function serves as a "constructor" for every new sale,
     * changes the state to active
     * @param _duration of the auction in seconds
     * @param _startingPrice of whatever is being sold in wei
     * @param _startingPrice in wei
     */
    function activateSale(uint256 _duration, uint256 _startingPrice, uint256 _finalPrice) external onlyOwner() {
        require(!isSaleActive, "Sale is already active");
        duration = _duration;
        startingPrice = _startingPrice;
        isSaleActive = true;
        saleStartTime = block.timestamp;
        finalPrice = _finalPrice;

        emit NewSale(_duration, _startingPrice, _finalPrice, saleStartTime);
    }

    /**
     * @notice deactivates current sale
     */
    function deactivateSale() external whenSaleIsActive() onlyOwner() {
        emit StopCurrentSale(getSaleElapsedTime(), getPrice());

        isSaleActive = false;
        saleStartTime = 0;
    }

    /**
     * @notice calculates current price when sale is active
     * @return price in wei
     */
    function getPrice() public view whenSaleIsActive() returns (uint256) {
        uint256 elapsed = getSaleElapsedTime();
        if (elapsed > duration) {
            return finalPrice;
        } else {
            uint256 price = ((duration - elapsed) * startingPrice) / duration;
            return price > finalPrice ? price : finalPrice;
        }
    }

    /**
     * @notice calculates time since the sale started
     * @return time left in seconds
     */
    function getSaleElapsedTime()
        internal
        view
        whenSaleIsActive()
        returns (uint256)
    {
        return saleStartTime > 0 ? block.timestamp - saleStartTime : 0;
    }
}