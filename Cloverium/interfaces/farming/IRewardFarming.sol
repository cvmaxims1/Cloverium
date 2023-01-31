//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../ILPPoolSnapshot.sol";

interface IRewardFarming {
    event RewardClaimed(
        address indexed rwToken,
        address indexed lpPool,
        address user,
        uint256 amount
    );

    /**
     * @dev LP pool hold shares of user
     */
    function lpPool() external view returns (ILPPoolSnapshot);

    /**
     * @dev token used for reward
     */
    function rwToken() external view returns (address);

    /**
     * @dev claims exchange reward for user to `to` wallet
     */
    function claims(address to) external;

    /**
     * @dev query claimable exchange rewards for user
     */
    function claimable(address owner) external view returns (uint256);
}
