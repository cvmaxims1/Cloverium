//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../roles/RoleGuard.sol";
import "../interfaces/IHookCallee.sol";
import "../interfaces/IHookCaller.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

abstract contract SKHookCaller is RoleGuard {
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet internal _hooks;

    /**
     * @dev notify lp being changed to hooks
     * @param user lp owner
     */
    function _harvestLPReward(address user) internal {
        unchecked {
            uint256 length = _hooks.length();
            for (uint256 i = 0; i < length; i++) {
                IHookCallee(_hooks.at(i)).lpProductHarvest(user);
            }
        }
    }

    /**
     * @dev notify lp changed to hooks
     * @param user lp owner
     */
    function _updateLPRewardDebt(address user) internal {
        unchecked {
            uint256 length = _hooks.length();
            for (uint256 i = 0; i < length; i++) {
                IHookCallee(_hooks.at(i)).lpProductUpdate(user);
            }
        }
    }

    /**
     * @dev add hook callback
     * @param observer hook callee
     */
    function addHook(IHookCallee observer) public onlyFarmControl {
        require(address(observer) != address(0), "INV_HOOK");
        _hooks.add(address(observer));
    }

    /**
     * @dev remove hook callback
     * @param observer hook callee
     */
    function removeHook(IHookCallee observer) public onlyFarmControl {
        require(address(observer) != address(0), "INV_HOOK");
        _hooks.remove(address(observer));
    }
}
