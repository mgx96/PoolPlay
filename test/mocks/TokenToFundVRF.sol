// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

/// @title Mock LINK Token
/// @notice A simple ERC20 mock to simulate Chainlink's LINK token in tests
contract MockToken is ERC20 {
    constructor(uint256 initialSupply) ERC20("Chainlink Token", "LINK") {
        _mint(msg.sender, initialSupply);
    }

    /// @notice Mint new LINK tokens to an address (for tests only)
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}
