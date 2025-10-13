// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {IPriceFeed} from "../interfaces/IPriceFeed.sol";

interface ISpotter {
    struct Collateral {
        IPriceFeed priceFeed; // the priceFeed Of Collateral
        // mat is ray e.g 1e27
        uint256 liquidationRatio; // this is the liquidation  ratio aka safety margin that deiced the minimum fund must e i an vault to not to be liquidate
    }

    function collaterals(bytes32 _colType) external returns (Collateral memory);

    function poke(bytes32 _colType) external;

    function par() external returns (uint256);
}
