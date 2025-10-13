// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

interface IINRC {
    function mint(address to, uint256 amount) external;

    function burn(address to, uint256 amount) external;
}
