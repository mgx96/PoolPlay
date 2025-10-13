// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Auth} from "../lib/Auth.sol";
import {CircuitBreaker} from "../lib/CircuitBreaker.sol";
import {RAD} from "../lib/Math.sol";
import {ICDPEngine} from "../interfaces/ICDPEngine.sol";

interface IINRC {
    function mint(address to, uint256 amount) external;

    function burn(address to, uint256 amount) external;
}

// this contract is also like gemJoin that handles user's collateral managgemnet and mint or bunrs our inrc stablecoin token aka borrow our inrc stablecoin token this stage comes after the user locked their collatral value it is like transfer from mean this will call

contract INRCJoin is CircuitBreaker, Auth {
    // interface of main our inrc stablecoin token
    IINRC public inrcToken;
    //intreface of vat token
    ICDPEngine public cdpEngine;

    event Joined(address indexed user, uint256 wad);
    event Exits(address indexed user, uint256 wad);

    constructor(address _cdpEngine, address _inrcToken) {
        inrcToken = IINRC(_inrcToken);
        cdpEngine = ICDPEngine(_cdpEngine);
    }

    function stop() external auth {
        _stop();
    }

    // here its burning the token that user brought with himself and minting actual our inrc stablecoin in his vat wallet mean as we know that it stores tokens in 1e45 so it storing internally  RAD * wad and burning ans opposite  when user exits
    function join(address _user, uint256 wad) external {
        //Why 1e45? Because Vat stores balances as rad — combining token amount (wad, 1e18) with high-precision rates (ray, 1e27).
        // This allows MakerDAO to apply interest rates accurately on huge numbers without rounding errors
        cdpEngine.transferInrc(address(this), _user, RAD * wad);
        inrcToken.burn(_user, wad);
        emit Joined(_user, wad);
    }

    function exit(address _user, uint256 wad) external notStopped {
        cdpEngine.transferInrc(_user, address(this), RAD * wad);
        inrcToken.mint(_user, wad);
        emit Exits(_user, wad);
    }
}
