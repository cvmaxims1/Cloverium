//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/farming/ISyrupBar.sol";
import "../libraries/InitializeGuard.sol";
import "../libraries/TransferHelper.sol";
import "./RewardFarming.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract SyrupBarFarming is RewardFarming, InitializeGuard {
    using SafeMath for uint256;
    /**
     * @dev reward token minter
     */
    ISyrupBar public syrup;
    /**
     * @dev keep track of total reward per block
     */
    uint256 public rewardPerBlock;
    /**
     * @dev keep track of last bonus block
     */
    uint256 public bonusEndBlock;
    /**
     * @dev keep track of last reward block
     */
    uint256 public lastRewardBlock;
    /**
     * @dev keep track of latest reward block for pool
     */
    mapping(address => uint256) public lastPoolRewardBlock;

    function initialize(
        address rwToken_,
        address syrup_,
        address lpPool_,
        uint256 rewardPerBlock_,
        uint256 startBlock_,
        uint256 duration_
    ) external uninitialized {
        rwToken = rwToken_;
        lpPool = ILPPoolSnapshot(lpPool_);
        syrup = ISyrupBar(syrup_);
        rewardPerBlock = rewardPerBlock_;
        if (startBlock_ > block.number) {
            lastRewardBlock = startBlock_;
        } else {
            lastRewardBlock = block.number;
        }
        bonusEndBlock = lastRewardBlock.add(duration_);
    }

    function migrate(address migrator) external onlyOwner {
        (bool success, ) = address(syrup).call(
            abi.encodeWithSignature("migrate(address)", migrator)
        );
        require(success, "MIGRATE_FAILED");
    }

    function addRewards(uint256 amount) external {
        require(amount > 0, "INV_AMOUNT");
        TransferHelper.safeTransferFrom(rwToken, _msgSender(), address(this), amount);
        TransferHelper.safeTransfer(rwToken, address(syrup), amount);
    }

    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        if (_to <= bonusEndBlock) {
            return _to.sub(_from);
        } else if (_from >= bonusEndBlock) {
            return 0;
        } else {
            return bonusEndBlock.sub(_from);
        }
    }

    //----mutate state----//
    function setRewardPerBlock(uint256 rewardPerBlock_) external onlyOwner {
        _updatePool();
        rewardPerBlock = rewardPerBlock_;
    }

    function setBonusEndBlock(uint256 endBlock_) external onlyOwner {
        require(lastRewardBlock <= endBlock_, "INV_END");
        bonusEndBlock = endBlock_;
    }

    function claims(address to) external override {
        _claims(_msgSender(), to);
    }

    function claimable(address user) external view override returns (uint256) {
        uint256 lpShares = lpPool.balanceOf(user);
        uint256 totalShares = lpPool.totalSupply();
        uint256 perShare_ = accPerShare;
        uint256 lastBlock = lastRewardBlock;
        if (block.number > lastBlock && totalShares > 0) {
            uint256 multiplier = getMultiplier(lastBlock, block.number);
            uint256 remainRewards = multiplier.mul(rewardPerBlock);
            perShare_ = perShare_.add(remainRewards.mul(REWARD_PER_SHARES).div(totalShares));
        }

        uint256 reward = lpShares.mul(perShare_).div(REWARD_PER_SHARES);
        UserInfo storage userInfo = _users[user];
        return reward.add(userInfo.pending).sub(userInfo.debt);
    }

    function _claims(address user, address to) internal {
        _updatePool();
        UserInfo storage userInfo = _users[user];

        uint256 lpShares = lpPool.balanceOf(user);
        uint256 debt = lpShares.mul(accPerShare).div(REWARD_PER_SHARES);
        uint256 pending = debt.sub(userInfo.debt);
        uint256 amount = userInfo.pending.add(pending);
        require(amount > 0, "INV_NO_REWARD");

        userInfo.pending = 0;
        userInfo.debt = debt;

        IERC20 rwToken_ = IERC20(rwToken);
        uint256 balance = rwToken_.balanceOf(to);
        syrup.mint(to, amount);
        uint256 minted = rwToken_.balanceOf(to).sub(balance);
        require(minted >= amount, "INV_NOT_ENOUGH_BALANCE");

        emit RewardClaimed(rwToken, address(lpPool), user, amount);
    }

    function _safeClaims(address user, address to) internal {
        _updatePool();
        UserInfo storage userInfo = _users[user];

        uint256 lpShares = lpPool.balanceOf(user);
        uint256 debt = lpShares.mul(accPerShare).div(REWARD_PER_SHARES);
        uint256 pending = debt.sub(userInfo.debt);
        uint256 amount = userInfo.pending.add(pending);
        if (amount == 0) {
            return;
        }
        userInfo.debt = debt;
        IERC20 rwToken_ = IERC20(rwToken);
        uint256 balance = rwToken_.balanceOf(to);
        syrup.mint(to, amount);
        uint256 minted = rwToken_.balanceOf(to).sub(balance);

        userInfo.pending = amount.sub(minted);
        emit RewardClaimed(rwToken, address(lpPool), user, minted);
    }

    function _updatePool() internal {
        uint256 totalShares = lpPool.totalSupply();
        if (totalShares > 0) {
            uint256 multiplier = getMultiplier(lastRewardBlock, block.number);
            uint256 remainRewards = multiplier.mul(rewardPerBlock);
            accPerShare = accPerShare.add(remainRewards.mul(REWARD_PER_SHARES).div(totalShares));
        }
        lastRewardBlock = block.number;
    }

    function _updateDebt(address user) internal {
        _users[user].debt = lpPool.balanceOf(user).mul(accPerShare).div(REWARD_PER_SHARES);
    }
}
