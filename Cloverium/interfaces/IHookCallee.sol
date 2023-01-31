//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IHookCallee {
    /**
     * @dev get call before LP changed
     * @param user lp owner user
     */
    function lpProductHarvest(address user) external;

    /**
     * @dev get call after LP changed
     * @param user lp owner user
     */
    function lpProductUpdate(address user) external;
}
