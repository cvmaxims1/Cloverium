//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract InitializeGuard {
    uint256 internal _initialized = 1;

    modifier uninitialized() {
        _checkInitialized();
        _;
    }

    function _checkInitialized() internal {
        require(_initialized == 1, "INV_INITIALIZED");
        _initialized = 0;
    }
}
