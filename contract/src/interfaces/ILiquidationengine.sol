// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface ILiquidationengine {
    function penalty(bytes32 _colType) external returns (uint256);

    function removeCoinFromAuction(bytes32 _colType, uint256 rad) external;
}
