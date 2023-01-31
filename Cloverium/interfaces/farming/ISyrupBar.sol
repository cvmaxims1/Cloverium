//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISyrupBarMigrator {
    function migrate(uint256 amount) external;
}

interface ISyrupBar {
    /**
     * @dev mint amount tokens to `to` user
     * Requirements:
     * - only accept call from syrup owner
     */
    function mint(address to, uint256 amount) external;
}
