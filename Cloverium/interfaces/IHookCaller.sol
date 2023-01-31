//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IHookCallee.sol";
import "./ILPPool.sol";

interface IHookCaller is ILPPool {
    function addHook(IHookCallee observer) external;

    function removeHook(IHookCallee observer) external;
}
