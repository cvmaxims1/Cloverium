//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../interfaces/fee/IFeeCollector.sol";
import "../../interfaces/staking/IStakePeriodProvider.sol";
import "../../libraries/TransferHelper.sol";
import "./SKStorage.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

abstract contract SKPool is SKStorage {
    using SafeMath for uint256;
    uint32 public constant DEFAULT_COMPOUND_DELAY = 2 days;
    uint32 public constant ONE_HUNDRED_PERCENT = 100_000; // 100.000

    // stake events
    event Staked(
        uint256 indexed stakeId,
        address indexed to,
        address indexed token,
        uint256 amount,
        uint256 shares,
        uint256 period
    );
    event Unstaked(uint256 indexed stakeId, uint256 amount);

    /**
     * @dev Staking periods provider
     */
    IStakePeriodProvider public periods;
    /**
     * @dev Unlock early penalty fee
     */
    uint32 public penaltyFee;
    /**
     * @dev penalty fee to address
     */
    address public penaltyFeeTo;

    // modify state for stake
    function _stake(
        address sender,
        address token,
        uint192 amount,
        uint32 lockDuration
    ) internal returns (uint256 stakeId) {
        uint192 lockedAmount = _refixAmount(token, amount);
        require(lockedAmount > 0, "INV_AMOUNT");
        TransferHelper.safeTransferFrom(token, sender, address(this), lockedAmount);
        (, uint32 allocPoint, ) = periods.byDurationPeriod(lockDuration);
        uint256 earnedShares = _calcEarnedShares(token, lockedAmount, allocPoint);
        stakeId = _mintStake(sender, token, lockDuration, amount, earnedShares);
        emit Staked(stakeId, sender, token, amount, earnedShares, lockDuration);
    }

    function _unstake(uint256 stakeId) internal virtual {
        require(_exists(stakeId), "INV_NO_EXIST");
        _beforeUnstake(stakeId);
        StakeInfo storage info = _stakes[stakeId];
        (uint256 unlockTime, uint256 minUnlockTime) = periods.calcUnlockTimeByDuration(
            info.period,
            info.start
        );
        require(block.timestamp >= minUnlockTime, "INV_NO_EXPIRED");
        if (block.timestamp < unlockTime) {
            _unstakePrior(stakeId);
        } else {
            _unstakeFull(stakeId);
        }
    }

    function _unstakePrior(uint256 stakeId) internal virtual {
        address owner = ownerOf(stakeId);
        require(_msgSender() == owner, "NOT_A_STAKE_OWNER");
        StakeInfo storage info = _stakes[stakeId];
        address token = info.token;
        (uint256 amount, ) = _burnStake(stakeId);
        if (penaltyFee != 0 && penaltyFeeTo != address(0)) {
            uint256 burnAmount = amount.mul(penaltyFee).div(ONE_HUNDRED_PERCENT);
            amount = amount.sub(burnAmount);
            if (burnAmount > 0) {
                TransferHelper.safeTransfer(token, penaltyFeeTo, burnAmount);
                IFeeCollector(penaltyFeeTo).collect(token);
            }
        }
        TransferHelper.safeTransfer(token, owner, amount);
        emit Unstaked(stakeId, amount);
    }

    function _unstakeFull(uint256 stakeId) internal virtual {
        address owner = ownerOf(stakeId);
        StakeInfo storage info = _stakes[stakeId];
        (uint192 amount, ) = _burnStake(stakeId);
        TransferHelper.safeTransfer(info.token, owner, amount);
        emit Unstaked(stakeId, amount);
    }

    // helpers
    function _refixAmount(address token, uint192 amount) internal view virtual returns (uint192) {
        return amount;
    }

    function _calcEarnedShares(
        address token,
        uint192 amount,
        uint32 allocPoint
    ) internal view virtual returns (uint256) {
        uint256 shares = amount;
        return shares.mul(allocPoint);
    }

    function _msgSender() internal view virtual returns (address);

    function _beforeUnstake(uint256 stakeId) internal virtual {}
}
