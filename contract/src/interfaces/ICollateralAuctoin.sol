// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface ICOllateralAuction {
    function collateralType() external view returns (bytes32);

    function start(
        // tab
        uint256 inrcAmount,
        //let
        uint256 collAmount,
        //user
        address user,
        //kpr
        address keeper
    ) external returns (uint256);
}
