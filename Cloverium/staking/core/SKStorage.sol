//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

abstract contract SKStorage {
    using EnumerableSet for EnumerableSet.UintSet;
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    struct StakeInfo {
        uint32 start; // keep track of start staking timestamp
        uint32 period; // keep track of period
        address token; // keep track of staked token
        uint192 amount; // keep track of staked amount
        uint256 shares; // keep track of earned shares
    }

    struct Reserve {
        uint256 reserve;
    }

    /**
     * @dev keep track of stake info by stake id (stakeId => info)
     */
    mapping(uint256 => StakeInfo) internal _stakes;

    /**
     * @dev Keep track of mapping from stake id to its owner (stakeId => owner)
     */
    mapping(uint256 => address) private _owners;

    /**
     * @dev Keep track of stake ids for owner (owner => set)
     */
    mapping(address => EnumerableSet.UintSet) private _owned;

    /**
     * @dev Last stake id
     */
    Counters.Counter private _currentStakeId;

    function ownerOf(uint256 stakeId) public view returns (address) {
        address owner = _owners[stakeId];
        require(owner != address(0), "INV_NO_EXIST");
        return owner;
    }

    function stakeOwnedBy(address account) public view returns (uint256) {
        return _owned[account].length();
    }

    function stakeIdAt(address account, uint256 index) public view returns (uint256) {
        return _owned[account].at(index);
    }

    function stakes(uint256 stakeId) public view returns (StakeInfo memory) {
        require(_exists(stakeId), "INV_NO_EXISTS");
        return _stakes[stakeId];
    }

    /**
     * @dev Creates a new stake and returns its stake id.
     */
    function _nextStakeId() private returns (uint256) {
        _currentStakeId.increment();
        return _getCurrentStakeId();
    }

    /**
     * @dev Get the current stake id
     */
    function _getCurrentStakeId() internal virtual returns (uint256) {
        return _currentStakeId.current();
    }

    function _mintStake(
        address account,
        address token,
        uint32 period,
        uint192 amount,
        uint256 shares
    ) internal returns (uint256) {
        _beforeTransferStake(address(0), account, token, amount, shares);
        uint256 stakeId = _nextStakeId();
        // update stake info
        StakeInfo storage info = _stakes[stakeId];
        info.token = token;
        info.period = period;
        info.start = SafeCast.toUint32(block.timestamp);
        info.amount = amount;
        info.shares = shares;

        // update user info
        EnumerableSet.UintSet storage owned = _owned[account];
        owned.add(stakeId);
        _owners[stakeId] = account;

        _afterTransferStake(address(0), account, token, amount, shares);
        return stakeId;
    }

    function _burnStake(uint256 stakeId) internal returns (uint192 amount, uint256 shares) {
        address account = _owners[stakeId];
        StakeInfo storage info = _stakes[stakeId];
        amount = info.amount;
        shares = info.shares;
        address token = info.token;
        _beforeTransferStake(account, address(0), token, amount, shares);
        EnumerableSet.UintSet storage owned = _owned[account];
        // clear stakeId
        owned.remove(stakeId);
        delete _owners[stakeId];
        delete _stakes[stakeId];
        _afterTransferStake(account, address(0), token, amount, shares);
    }

    function _updateStakeShares(
        Reserve storage holder,
        uint192 amount,
        function(uint256, uint256) view returns (uint256) op
    ) internal {
        holder.reserve = op(holder.reserve, amount);
    }

    function _exists(uint256 stakeId) internal view returns (bool) {
        address owner = _owners[stakeId];
        return owner != address(0);
    }

    function _beforeTransferStake(
        address from,
        address to,
        address token,
        uint192 amount,
        uint256 shares
    ) internal virtual {}

    function _afterTransferStake(
        address from,
        address to,
        address token,
        uint192 amount,
        uint256 shares
    ) internal virtual {}

    function _add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a.add(b);
    }

    function _subtract(uint256 a, uint256 b) internal pure returns (uint256) {
        return a.sub(b);
    }
}
