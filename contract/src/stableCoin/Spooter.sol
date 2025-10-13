// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Auth} from "../lib/Auth.sol";
import {ICDPEngine} from "../interfaces/ICDPEngine.sol";
import {CircuitBreaker} from "../lib/CircuitBreaker.sol";
import {Math} from "../lib/Math.sol";

interface IPriceFeed {
    error PriceFeed_InvalidPrice();

    function peek() external returns (uint256, bool);
}

// this contract  fetch pricesFeed from pip contract and set IT to VAT contract aka cdp
contract Spotter is Auth, CircuitBreaker {
    error SPotter_LeyNotRecognized(bytes32 _key);

    ICDPEngine public cdpEngine; // vat contract

    // iiks=  stores collateral priceFeed and thier price in refernce of
    struct Collateral {
        IPriceFeed priceFeed; // the priceFeed Of Collateral
        // mat is ray e.g 1e27
        uint256 liquidationRatio; // this is the liquidation  ratio aka safety margin that deiced the minimum fund must e i an vault to not to be liquidate
    }

    event Poke(bytes32 _colType, uint256 _val, uint256 _spot);

    mapping(bytes32 => Collateral) public collaterals;
    uint256 public par; // it's the price of INRCToken to its refernce collateral basically its like the price oF DAI in terms of USD

    constructor(address _cdpEngine) {
        cdpEngine = ICDPEngine(_cdpEngine);
        par = 10 ** 27;
    }

    // file
    // this is for chanhing the pricedFeed of collateral
    function set(bytes32 _colType, bytes32 _key, address _data) external auth notStopped {
        if (_key != "priceFeed") revert SPotter_LeyNotRecognized(_key);
        collaterals[_colType].priceFeed = IPriceFeed(_data);
    }

    // file
    // for changing the liquidation ratio of collateral
    function set(bytes32 _colType, bytes32 _key, uint256 _data) external auth notStopped {
        if (_key != "liquidationRatio") revert SPotter_LeyNotRecognized(_key);
        collaterals[_colType].liquidationRatio = _data;
    }

    // file
    //par defines what “1 DAI” is supposed to be worth relative to the system’s base unit (USD, INR, etc.)
    // spot = (collateralPrice * par) / mat
    function set(bytes32 _key, uint256 _data) external auth notStopped {
        if (_key != "par") revert SPotter_LeyNotRecognized(_key);
        par = _data;
    }

    // this is for changing the spot priceOfCollateral in cdp where spot priee aka currnet market Price;
    // so spot price =price / mat = ( price * par) / mat very in 1e27 and mat is in 150% as 150 which 1.5
    function poke(bytes32 _colType) external {
        (uint256 price, bool isOk) = collaterals[_colType].priceFeed.peek();
        // If price, par, and liquidationRatio are all in ray (1e27), this will overflow or lose precision, because multiplying two rays gives 1e54 scale before division
        uint256 spot = isOk ? Math.rdiv(Math.rdiv(price * 10 ** 9, par), collaterals[_colType].liquidationRatio) : 0;
        cdpEngine.set(_colType, "spot", spot);
        emit Poke(_colType, price, spot);
    }

    function stop() external auth {
        _stop();
    }
}
