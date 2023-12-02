// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

contract ReentrancyGuard {
    bool internal locked;

    constructor () {
        locked = false;
    }

    modifier noReentrant() {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }
}
