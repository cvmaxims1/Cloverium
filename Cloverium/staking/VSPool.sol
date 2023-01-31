//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../tokens/vTokenSnapshot.sol";
import "../libraries/InitializeGuard.sol";
import "../interfaces/staking/extensions/IVSPoolAdmin.sol";
import "./core/SKPool.sol";
import "./SKHookCaller.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract VSPool is
    vTokenSnapshot,
    SKPool,
    SKHookCaller,
    Ownable,
    ReentrancyGuard,
    InitializeGuard,
    IVSPoolAdmin
{
    using SafeMath for uint256;

    constructor() vToken("VSPool-LP", "vRRT") ReentrancyGuard() {}

    /**
     * @dev keep track of total reserve (token => Reserve)
     */
    mapping(address => Reserve) private _tokenReserves;
    /**
     * @dev keep track of user reserve; (account => (token => Reserve))
     */
    mapping(address => mapping(address => Reserve)) private _userReserves;

    //-----pool admin-----//
    /**
     * @dev keep track of enable token for stake and its allocPoint
     * (token => allocPoint)
     */
    mapping(address => uint32) public override allocPointFor;
    /**
     * @dev keep track of wei value per shares
     * (token => weiPerShare)
     */
    mapping(address => uint256) internal _weiPerShares;

    //-----end pool admin-----//

    function initialize(address periods_) public virtual onlyOwner uninitialized {
        periods = IStakePeriodProvider(periods_);
    }

    function totalReserved(address token) external view returns (uint256) {
        return _tokenReserves[token].reserve;
    }

    function userReserved(address account, address token) external view returns (uint256) {
        return _userReserves[account][token].reserve;
    }

    function stake(
        address token,
        uint192 amount,
        uint32 lockDuration
    ) external nonReentrant returns (uint256) {
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

    function enableToken(address token, uint32 allocPoint) external override onlyOperator {
        allocPointFor[token] = allocPoint;
        if (allocPoint > 0) {
            uint256 decimals = IERC20Metadata(token).decimals();
            _weiPerShares[token] = 10**decimals;
        } else {
            _weiPerShares[token] = 0;
        }
        emit StakeTokenSet(token, allocPoint);
    }

    function setPenaltyFeeTo(address feeTo, uint32 percent) external onlyOperator {
        require(percent <= ONE_HUNDRED_PERCENT, "INV_PERCENT");
        penaltyFee = percent;
        penaltyFeeTo = feeTo;
    }

    // stake amount fix
    function _refixAmount(address token, uint192 stakeAmount)
        internal
        view
        override
        returns (uint192)
    {
        uint256 perShare = _weiPerShares[token];
        require(perShare > 0, "INV_TOKEN");
        uint256 amount_ = stakeAmount;
        return uint192(amount_.div(perShare).mul(perShare));
    }

    function _calcEarnedShares(
        address token,
        uint192 amount,
        uint32 allocPoint
    ) internal view override returns (uint256) {
        uint256 shares = amount;
        return
            shares.div(_weiPerShares[token]).mul(10**18).mul(allocPointFor[token]).mul(allocPoint);
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
            _updateStakeShares(_userReserves[to][token], amount, _add);
            _updateStakeShares(_tokenReserves[token], amount, _add);
            _mint(to, shares);
            _updateLPRewardDebt(to);
        } else if (to == address(0)) {
            // burn stake
            _updateStakeShares(_userReserves[from][token], amount, _subtract);
            _updateStakeShares(_tokenReserves[token], amount, _subtract);
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
