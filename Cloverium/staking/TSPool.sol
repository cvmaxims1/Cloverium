//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../tokens/vTokenSnapshot.sol";
import "../libraries/InitializeGuard.sol";
import "./core/SKPool.sol";
import "./SKHookCaller.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TSPool is vTokenSnapshot, SKPool, SKHookCaller, Ownable, ReentrancyGuard, InitializeGuard {
    constructor() vToken("TSPool-LP", "vTS") ReentrancyGuard() {}

    /**
     * @dev keep track of total reserve
     */
    Reserve private _totalReserves;
    /**
     * @dev keep track of user reserves;
     */
    mapping(address => Reserve) private _userReserves;

    /**
     * @dev Staking token
     */
    address public token;

    function initialize(address token_, address periods_) public virtual onlyOwner uninitialized {
        token = token_;
        periods = IStakePeriodProvider(periods_);
    }

    function totalReserved() external view returns (uint256) {
        return _totalReserves.reserve;
    }

    function userReserved(address account) external view returns (uint256) {
        return _userReserves[account].reserve;
    }

    function stake(uint192 amount, uint32 lockDuration) external nonReentrant returns (uint256) {
        address sender = _msgSender();
        return _stake(sender, token, amount, lockDuration);
    }

    function unstake(uint256 stakeId) external nonReentrant {
        _unstake(stakeId);
    }

    //-----restrict functions-----//
    function snapshot() external canSnapshot returns (uint256) {
        return _snapshot();
    }

    function setPenaltyFeeTo(address feeTo, uint32 percent) external onlyOperator {
        require(percent <= ONE_HUNDRED_PERCENT, "INV_PERCENT");
        penaltyFee = percent;
        penaltyFeeTo = feeTo;
    }

    // stake hooks
    function _beforeTransferStake(
        address from,
        address to,
        address token,
        uint192 amount,
        uint256 shares
    ) internal override {
        if (from == address(0)) {
            // mint stake
            _harvestLPReward(to);
        } else if (to == address(0)) {
            // burn stake
            _harvestLPReward(from);
        }
    }

    function _afterTransferStake(
        address from,
        address to,
        address token,
        uint192 amount,
        uint256 shares
    ) internal override {
        if (from == address(0)) {
            // mint stake
            _updateStakeShares(_userReserves[to], amount, _add);
            _updateStakeShares(_totalReserves, amount, _add);
            _mint(to, shares);
            _updateLPRewardDebt(to);
        } else if (to == address(0)) {
            // burn stake
            _updateStakeShares(_userReserves[from], amount, _subtract);
            _updateStakeShares(_totalReserves, amount, _subtract);
            _burn(from, shares);
            _updateLPRewardDebt(from);
        }
    }

    // resolve conflict
    function _msgSender() internal view override(Context, RoleGuard, SKPool) returns (address) {
        return Context._msgSender();
    }

    function isOwner() public view override returns (bool) {
        return owner() == _msgSender();
    }

    function _beforeUnstake(uint256 stakeId) internal view override {
        address sender = _msgSender();
        require(ownerOf(stakeId) == sender || hasRole(OPERATOR_ROLE, sender), "INV_NO_PERMISSION");
    }
}
