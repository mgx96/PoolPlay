// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

//we only use interface when we has to call any function of that contract so we don't need to have extra storage gor that
interface IGem {
    function decimals() external returns (uint8);

    function transfer(address, uint256) external returns (bool);

    function transferFrom(address, address, uint256) external returns (bool);
}
