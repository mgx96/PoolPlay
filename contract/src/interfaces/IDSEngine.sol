// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IDSEngine {
    //fees
    function pushDebtToQueue(uint256 debt) external;
}
