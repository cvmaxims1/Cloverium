//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./farming/IRewardFarming.sol";

interface IFarmingCreator {
    function createFarming(
        address rwToken,
        address lpPool,
        bytes calldata data
    ) external returns (address farming);
}
