//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/ILPPool.sol";
import "../interfaces/voting/IPoolVoting.sol";
import "../interfaces/ICloveriumFactory.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PoolVoting is IPoolVoting, Ownable {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    uint8 public constant DEFAULT_MAX_VOTING_POOL_COUNT = 5;

    ICloveriumFactory internal _exchangeFactory;

    uint8 internal _maxPoolVotes;
    ILPPool public lp;
    uint256 public override totalVotes;
    mapping(address => uint256) public override poolVotes;
    mapping(address => uint256) public override userVotes;
    mapping(address => mapping(address => uint256)) public override userPoolVotes;
    mapping(address => EnumerableSet.AddressSet) internal _userPools;

    constructor(address exchangeFactory, address lp_) Ownable() {
        require(exchangeFactory != address(0), "INV_EXCHANGE");
        require(lp_ != address(0), "INV_LP");
        _exchangeFactory = ICloveriumFactory(exchangeFactory);
        lp = ILPPool(lp_);
    }

    function maxPoolVotes() public view override returns (uint8) {
        if (_maxPoolVotes > 0) {
            return _maxPoolVotes;
        }
        return DEFAULT_MAX_VOTING_POOL_COUNT;
    }

    function setMaxPoolVotes(uint8 maxPool) external override onlyOwner {
        _maxPoolVotes = maxPool;
    }

    function userRemainVotes(address user) external view override returns (uint256) {
        uint votes = lp.balanceOf(user);
        if (votes <= userVotes[user]) {
            return 0;
        }
        return votes.sub(userVotes[user]);
    }

    function userVotingLPCount(address user) public view override returns (uint256) {
        return _userPools[user].length();
    }

    function userVotingPoolAddress(address user, uint256 lpIndex)
        public
        view
        override
        returns (address)
    {
        return _userPools[user].at(lpIndex);
    }

    function userVotingPoolAmount(address user, uint256 lpIndex)
        public
        view
        override
        returns (uint256)
    {
        address exchange = userVotingPoolAddress(user, lpIndex);
        return userPoolVotes[user][exchange];
    }

    function addVoting(address exchange, uint256 amount) public override {
        require(amount > 0, "INV_AMOUNT");
        require(_exchangeFactory.isPair(exchange), "INV_EXCHANGE");
        _addVoting(_msgSender(), exchange, amount);
    }

    function removeVoting(address exchange, uint256 amount) public override {
        require(amount > 0, "INV_AMOUNT");
        _removeVoting(_msgSender(), exchange, amount);
    }

    function removeAllVoting() public override {
        address user = _msgSender();
        address exchange;
        while (_userPools[user].length() > 0) {
            exchange = _userPools[user].at(0);
            _removeVoting(user, exchange, userPoolVotes[user][exchange]);
        }
    }

    function _addVoting(
        address user,
        address exchange,
        uint256 amount
    ) internal {
        EnumerableSet.AddressSet storage set = _userPools[user];
        set.add(exchange);
        require(set.length() <= maxPoolVotes(), "INV_MAX_POOL");
        userVotes[user] = userVotes[user].add(amount);
        require(userVotes[user] <= lp.balanceOf(user), "INSUFFICIENT");
        userPoolVotes[user][exchange] = userPoolVotes[user][exchange].add(amount);
        poolVotes[exchange] = poolVotes[exchange].add(amount);
        totalVotes = totalVotes.add(amount);

        emit AddVoting(user, exchange, amount);
    }

    function _removeVoting(
        address user,
        address exchange,
        uint256 amount
    ) internal {
        userVotes[user] = userVotes[user].sub(amount);
        userPoolVotes[user][exchange] = userPoolVotes[user][exchange].sub(amount);
        poolVotes[exchange] = poolVotes[exchange].sub(amount);
        totalVotes = totalVotes.sub(amount);
        if (userPoolVotes[user][exchange] == 0) {
            _userPools[user].remove(exchange);
        }
        emit RemoveVoting(user, exchange, amount);
    }
}
