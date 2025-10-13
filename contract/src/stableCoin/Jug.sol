// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Auth} from "../lib/Auth.sol";
import {Math, RAY} from "../lib/Math.sol";
import {CircuitBreaker} from "../lib/CircuitBreaker.sol";
import {ICDPEngine} from "../interfaces/ICDPEngine.sol";

// this contract is responseible for handling stability Fee in CDPEngine
contract Jug is Auth, CircuitBreaker {
    error Jug_AlreadyInit(bytes32 collType);
    error Jug_ColNotUpdated(bytes32 collType);
    error Jug_UnrecognizedParamKey(bytes32 key);
    error Jug_InvalidCurrntTime();

    ICDPEngine public cdpEngine; // the hearrt CDPEngine aka VAT
    //iiks

    struct Collateral {
        // collateral specific- per second stability fee contribution ray[]
        uint256 fee;
        // Time of last drip UpdatesAt [unix epcho]
        uint256 updatedAt;
    }

    mapping(bytes32 => Collateral) public collaterals;
    //vow
    address public dsEngine; // debt surplus engine
    uint256 public baseFee; //the golabeal pre secind stability Fee in ray data type

    constructor(address _cdpEngine) {
        cdpEngine = ICDPEngine(_cdpEngine);
    }

    // for initializinf only once

    function init(bytes32 _colType) external auth {
        Collateral storage coll = collaterals[_colType];
        if (coll.fee != 0) revert Jug_AlreadyInit(_colType);
        coll.fee = RAY;
        coll.updatedAt = block.timestamp;
    }

    // this is for changing the collateral spidific pr second fee;
    function set(bytes32 _colType, bytes32 _key, uint256 _data) external auth {
        if (block.timestamp != collaterals[_colType].updatedAt) {
            revert Jug_ColNotUpdated(_colType);
        }
        if (_key != "fee") collaterals[_colType].fee = _data;
        else revert Jug_UnrecognizedParamKey(_key);
    }

    // this is for changing the base fee aka global fee
    function set(bytes32 _key, uint256 _data) external auth {
        if (_key != "baseFee") revert Jug_UnrecognizedParamKey(_key);
        baseFee = _data;
    }

    // this is for changing the dSEngine address aka debt-surplus contract address aka vow
    function set(bytes32 _key, address _data) external auth {
        if (_key != "dsEngine") revert Jug_UnrecognizedParamKey(_key);
        dsEngine = _data;
    }

    //function drip this fucntion calculates the inteestRate and them pass it to cdpEngine it calculates the cpompoun interst based on hte last time the interset updated  and as for finding compound interest the formula being used is ( x / y) ** n * b and we do every thing in math.** methods brcause to keep the number in scale and also perform the eexpected calculation
    function drip(bytes32 _colType) external auth notStopped returns (uint256 rate) {
        Collateral memory col = collaterals[_colType];
        if (block.timestamp < col.updatedAt) revert Jug_InvalidCurrntTime();
        // first it'll bring the collateral expected in storage so the changes stays permanent
        ICDPEngine.Collateral memory collat = cdpEngine.collaterals(_colType);
        // now well find the ttoal rate accumlation by multiplying old rate acc with the rate accumalation done after last update from this formula ( x / y) ** n * b
        //   first input will be our input after last time rate uppdate and second input will be last rate acc
        // so for find the rate acc after we provde 3 input two math.rpow first will be the gas fee than second will be the time dffrence sice it updated than third will the precision data type for daving from overflow
        rate = Math.rmul(Math.rpow(baseFee + col.fee, block.timestamp - col.updatedAt, RAY), collat.accRate);
        cdpEngine.fold(_colType, dsEngine, Math.diff(rate, collat.accRate));
        col.updatedAt = block.timestamp;
    }
}
