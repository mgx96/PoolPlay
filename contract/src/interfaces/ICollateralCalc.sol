// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

interface ICollateralCalc {
    // top - starting price, dt time elapsed
    function price(uint256 top, uint256 timeElapsed) external view returns (uint256);
}
