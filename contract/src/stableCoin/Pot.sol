// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {CircuitBreaker} from "../lib/CircuitBreaker.sol";
import {Auth} from "../lib/Auth.sol";
import {Math, RAY} from "../lib/Math.sol";
import {ICDPEngine} from "../interfaces/ICDPEngine.sol";

contract Pot is Auth, CircuitBreaker {
    error Pot_InvalidTimeStamp();
    error Pot_UnrecognizedKeyParam();
    //vat

    ICDPEngine public cdpEngine;
    //pie
    // the saving the user has made
    mapping(address => uint256) public savings;
    // Pie = the normalized saving dai [wad]
    uint256 public totalPie;
    // dsr
    // the coin (dai) savings rate [ray]
    uint256 public savingRate;
    // vow = dsEngine
    address public dsEngine;
    //chi = rate accmulater [ray]
    uint256 public rateAcc;
    //rho = last time drip
    uint256 public updatedAt;

    // init
    constructor(address _cdpEngine) {
        cdpEngine = ICDPEngine(_cdpEngine);
        savingRate = RAY;
        rateAcc = RAY;
        updatedAt = block.timestamp;
    }

    // for sertting the saving rate but only when it's chaged dur to calling drip functoin mean reflects to every rate change
    function set(bytes32 _key, uint256 _newRate) external auth notStopped {
        if (block.timestamp != updatedAt) revert Pot_InvalidTimeStamp();
        if (_key == "savingRate") savingRate = _newRate;
        else revert Pot_UnrecognizedKeyParam();
    }

    // for updating the the address of dsEngine debt and surplus contract
    function set(bytes32 _key, address _address) external auth notStopped {
        if (_key != "dsEngine") revert Pot_UnrecognizedKeyParam();
        dsEngine = _address;
    }

    //to stpo
    function stop() external auth {
        _stop();
        savingRate = RAY;
    }

    //function for collecting the stability Fee
    function collectStabilityFee() external returns (uint256) {
        if (block.timestamp < updatedAt) revert Pot_InvalidTimeStamp();
        uint256 acc = Math.rmul(Math.rpow(savingRate, updatedAt - block.timestamp, RAY), rateAcc);
        uint256 deltaAcc = rateAcc - acc;
        rateAcc = acc;
        updatedAt = block.timestamp;
        // here the totalPie * delta rate is the difference of token from old to new
        // old Token = totalPie * old rate
        // newly token = totalPir *  new rate
        // difference token  = total * (old - new) = total * delta
        cdpEngine.mint(address(dsEngine), address(this), totalPie * deltaAcc);
        return acc;
    }

    // this id for when user is join by storing thier token in POT
    function join(uint256 _wad) external {
        if (block.timestamp != updatedAt) revert Pot_InvalidTimeStamp();
        savings[msg.sender] += _wad;
        totalPie += _wad;
        // we transfered token from user to the pot
        cdpEngine.transferInrc(msg.sender, address(this), rateAcc * _wad);
    }

    // this when user is exiting and taking back hhis stored token
    function exit(uint256 _wad) external {
        savings[msg.sender] -= _wad;
        totalPie -= _wad;
        cdpEngine.transferInrc(address(this), msg.sender, rateAcc * _wad);
    }
}
