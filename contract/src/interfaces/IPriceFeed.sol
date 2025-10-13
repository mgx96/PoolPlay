// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPriceFeed {
    error PriceFeed_InvalidPrice();

    function peek() external returns (uint256, bool);
}
