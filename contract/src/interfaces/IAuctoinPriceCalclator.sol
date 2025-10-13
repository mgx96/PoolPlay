// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

interface IAuctionPriceCalculator {
    function price(uint256 top, uint256 td) external view returns (uint256);
}
