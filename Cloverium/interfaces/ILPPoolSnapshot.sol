//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ILPPool.sol";

interface ILPPoolSnapshot is ILPPool {
    /**
     * @dev Take snapshot, return snapshot id
     */
    function snapshot() external returns (uint256);

    /**
     * @dev Get current snapshot id
     */
    function getCurrentSnapshotId() external view returns (uint256);

    /**
     * @dev Return total shares at block
     */
    function totalSupplyAt(uint256 snapshotId) external view returns (uint256);

    /**
     * @dev Return shares for account at block
     */
    function balanceOfAt(address account, uint256 snapshotId) external view returns (uint256);
}
