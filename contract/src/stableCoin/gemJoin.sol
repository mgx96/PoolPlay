// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Auth} from "../lib/Auth.sol";
import {CircuitBreaker} from "../lib/CircuitBreaker.sol";
import {ReentrancyGuard} from "lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import {ICDPEngine} from "../interfaces/ICDPEngine.sol";
import {IGem} from "../interfaces/IGem.sol";

/**
 * @title GemJoin
 * @notice This contract handles collateral tokens for a stablecoin system.
 * Users deposit their ERC20 collateral into this contract,
 * which then updates the vault balance in the main CDP Engine (Vat).
 */
contract GemJoin is Auth, CircuitBreaker, ReentrancyGuard {
    // ---------------------------
    // Errors
    // ---------------------------
    error GemJoin_OverFlow(); // Invalid collateral amount
    error GemJoin_TransactionFailed(); // ERC20 transfer failed

    // ---------------------------
    // State Variables
    // ---------------------------
    ICDPEngine public cdpEngine; // Interface to the main CDP Engine (Vat)
    bytes32 public collateralType; // Type of collateral (e.g., ETH-A, WBTC-A)
    IGem public gem; // Interface for ERC20 collateral token
    uint8 public decimals; // Collateral token decimals

    // ---------------------------
    // Events
    // ---------------------------
    event Joined(address indexed user, uint256 amount);
    event Exited(address indexed user, uint256 amount);

    // ---------------------------
    // Constructor
    // ---------------------------
    constructor(address _cdpEngine, address _gemToken, bytes32 _collateralType) {
        cdpEngine = ICDPEngine(_cdpEngine);
        gem = IGem(_gemToken);
        collateralType = _collateralType;
        decimals = gem.decimals();
    }

    // ---------------------------
    // Admin Functions
    // ---------------------------
    /// @notice Stop the contract in emergency
    function stop() external auth {
        _stop(); // CircuitBreaker functionality
    }

    // ---------------------------
    // User Functions
    // ---------------------------

    /**
     * @notice Lock collateral into the system (join)
     * @param _user The address of the user depositing collateral
     * @param _wad The amount of tokens to deposit (scaled to token decimals)
     *
     * @dev Updates the user's collateral balance in the CDP Engine (Vat)
     *      and transfers tokens from the user to this contract.
     *      Uses custom errors for failure conditions.
     */
    function join(address _user, uint256 _wad) external notStopped {
        if (int256(_wad) <= 0) revert GemJoin_OverFlow();

        // Update user collateral in Vat
        cdpEngine.modifyCollateralBalance(collateralType, _user, int256(_wad));

        // Transfer collateral tokens from user to this contract
        bool success = gem.transferFrom(_user, address(this), _wad);
        if (!success) revert GemJoin_TransactionFailed();

        emit Joined(_user, _wad);
    }

    /**
     * @notice Withdraw collateral from the system (exit)
     * @param _user The address of the user withdrawing collateral
     * @param _vad The amount of tokens to withdraw
     *
     * @dev Reduces the user's collateral balance in the CDP Engine (Vat)
     *      and transfers tokens back to the user.
     */
    function exit(address _user, uint256 _vad) external notStopped nonReentrant {
        if (_vad >= 2 ** 255) revert GemJoin_OverFlow();

        // Update user collateral in Vat
        cdpEngine.modifyCollateralBalance(collateralType, _user, -int256(_vad));

        // Transfer collateral tokens from contract to user
        bool success = gem.transfer(_user, _vad);
        if (!success) revert GemJoin_TransactionFailed();

        emit Exited(_user, _vad);
    }
}
