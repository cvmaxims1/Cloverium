//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IVSPoolAdmin {
    event StakeTokenSet(address token, uint32 allocPoint);

    /**
     * @dev Return alloc point shares for stake token
     */
    function allocPointFor(address token) external view returns (uint32);

    /**
     * @dev Enable or disable sk token for stake
     * Set `allocPoint` to zero to disable stake token for future stake
     * emit StakeTokenSet event
     */
    function enableToken(address token, uint32 allocPoint) external;
}
