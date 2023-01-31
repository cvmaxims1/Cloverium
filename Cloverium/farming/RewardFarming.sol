//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/farming/IRewardFarming.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

abstract contract RewardFarming is IRewardFarming, Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeMath for uint256;

    uint256 public constant REWARD_PER_SHARES = 1e12;

    struct UserInfo {
        uint256 pending;
        uint256 debt;
    }

    /**
     * @dev LP pool hold shares of user
     */
    ILPPoolSnapshot public override lpPool;
    /**
     * @dev token used for reward
     */
    address public override rwToken;
    /**
     * @dev keep track of acc reward per shares
     */
    uint256 public accPerShare;
    /**
     * @dev keep track user reward info (user => user info)
     */
    mapping(address => UserInfo) internal _users;
}
