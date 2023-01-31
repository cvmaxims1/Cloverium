//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../libraries/TransferHelper.sol";
import "../libraries/InitializeGuard.sol";
import "./RewardFarming.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface RewardFarmingMigrator {
    function migrate(address token, uint256 amount) external;
}

contract FixRewardFarming is RewardFarming, InitializeGuard {
    using SafeMath for uint256;

    event RewardAdded(address indexed rwToken, address indexed lpPool, uint256 amount);

    /**
     * @dev keep track pool debt (exchange => debt)
     */
    mapping(address => uint256) internal _poolsDebt;

    /**
     * @dev keep track of last add reward snapshot id
     */
    uint256 private _snapshotId;

    function initialize(address rwToken_, address lpPool_) external uninitialized {
        rwToken = rwToken_;
        lpPool = ILPPoolSnapshot(lpPool_);
    }

    function migrate(address migrator) external onlyOwner {
        IERC20 token = IERC20(rwToken);
        uint256 amount = token.balanceOf(address(this));
        token.approve(migrator, amount);
        RewardFarmingMigrator(migrator).migrate(rwToken, amount);
    }

    function addRewards(uint256 amount) external {
        require(amount > 0, "INV_AMOUNT");
        TransferHelper.safeTransferFrom(rwToken, _msgSender(), address(this), amount);
        uint256 totalSupply = lpPool.totalSupply();
        _snapshotId = lpPool.snapshot();
        if (totalSupply > 0) {
            accPerShare = accPerShare.add(amount.mul(REWARD_PER_SHARES).div(totalSupply));
        }
        emit RewardAdded(rwToken, address(lpPool), amount);
    }

    function claims(address to) external override {
        _claims(_msgSender(), to);
    }

    function claimable(address user) external view override returns (uint256) {
        if (_snapshotId == 0) {
            // no reward added
            return 0;
        }
        UserInfo storage userInfo = _users[user];
        uint256 lpShares = lpPool.balanceOfAt(user, _snapshotId);
        uint256 newPending = lpShares.mul(accPerShare).div(REWARD_PER_SHARES);
        return userInfo.pending.add(newPending).sub(userInfo.debt);
    }

    //------ low level functions ------//
    function _claims(address user, address to) internal {
        if (_snapshotId == 0) {
            // no reward added
            return;
        }
        UserInfo storage userInfo = _users[user];

        uint256 userShares = lpPool.balanceOfAt(user, _snapshotId);
        uint256 debt = userShares.mul(accPerShare).div(REWARD_PER_SHARES);
        uint256 amount = userInfo.pending.add(debt.sub(userInfo.debt));
        if (amount > 0) {
            userInfo.pending = 0;
            userInfo.debt = debt;
            TransferHelper.safeTransfer(rwToken, to, amount);
            emit RewardClaimed(rwToken, address(lpPool), user, amount);
        }
    }

    function _updateDebt(address user) internal {
        if (_snapshotId == 0) {
            // no reward added
            return;
        }
        _users[user].debt = lpPool.balanceOf(user).mul(accPerShare).div(REWARD_PER_SHARES);
    }
}
