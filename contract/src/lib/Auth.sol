// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// this contract is for authentication this will authorize the other account for access the authorization process

contract Auth {
    error Auth_NOTAUTHORIZED(address user);

    event GRANT_AUTHORIZED(address user);
    event DENIED_AUTHORIZATION(address user);

    mapping(address => bool) public authorized;

    constructor() {
        authorized[msg.sender] = true;
        emit GRANT_AUTHORIZED(msg.sender);
    }

    modifier auth() {
        if (authorized[msg.sender] != true) {
            revert Auth_NOTAUTHORIZED(msg.sender);
        }
        _;
    }

    function grantAuth(address _user) external auth {
        authorized[_user] = true;
        emit GRANT_AUTHORIZED(_user);
    }

    function deniedAuth(address _user) external auth {
        authorized[_user] = false;
        emit DENIED_AUTHORIZATION(_user);
    }
}
