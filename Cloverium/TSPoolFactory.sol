//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./staking/TSPool.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Create2.sol";

contract TSPoolFactory is Ownable {
    event PoolCreated(address indexed token, address pool);

    address public periods;
    address public accessControl;

    /**
     * @dev keep track of stake token to pool (token => pool)
     */
    mapping(address => address) public getPools;
    /**
     * @dev keep track of all pools
     */
    address[] public allPools;

    constructor(address periods_, address accessControl_) Ownable() {
        require(periods_ != address(0), "INV_PERIOD_PROVIDER");
        require(accessControl_ != address(0), "INV_ACCESS_CONTROL");
        periods = periods_;
        accessControl = accessControl_;
    }

    function allPoolsLength() external view returns (uint256) {
        return allPools.length;
    }

    function createPool(address token) external onlyOwner returns (address pool) {
        require(token != address(0), "INV_TOKEN");
        require(getPools[token] == address(0), "INV_EXISTS");
        bytes32 salt = keccak256(abi.encodePacked(token));
        pool = Create2.deploy(0, salt, type(TSPool).creationCode);
        TSPool pool_ = TSPool(pool);
        pool_.setRoleControl(accessControl);
        pool_.initialize(token, periods);
        pool_.transferOwnership(msg.sender);
        getPools[token] = pool;
        allPools.push(pool);

        emit PoolCreated(token, pool);
    }
}
