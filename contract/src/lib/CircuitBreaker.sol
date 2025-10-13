// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract CircuitBreaker {
    error CircuitBreaker_NotLive();

    bool public live; // indiccates is the contract live or not

    event Stopped();

    constructor() {
        live = true;
    }

    modifier notStopped() {
        if (live == false) revert CircuitBreaker_NotLive();
        _;
    }

    function _stop() internal {
        live = false;
        emit Stopped();
    }
}
