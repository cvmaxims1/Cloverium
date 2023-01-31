//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/fee/IFeeCollector.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FeeCollectorV1 is IFeeCollector, Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeMath for uint256;

    /**
     * @dev keep track of fees collect amount (collectFrom => (token => amount))
     */
    mapping(address => mapping(address => uint256)) public override feeCollects;
    /**
     * @dev keep track off fees collect amount by token
     */
    mapping(address => uint256) public override feeByTokens;
    /**
     * @dev keep track of enabled collect token
     */
    mapping(address => bool) public enabledTokens;
    /**
     * @dev keep track of enabled collect from
     */
    mapping(address => bool) public enabledSenders;

    EnumerableSet.AddressSet private _allFrom;
    EnumerableSet.AddressSet private _allToken;

    function collect(address token) external override {
        require(enabledTokens[token], "INV_TOKEN");
        address sender = msg.sender;
        require(enabledSenders[sender], "INV_SENDER");

        uint256 balance = IERC20(token).balanceOf(address(this));
        uint256 fee = balance.sub(feeByTokens[token]);
        feeByTokens[token] = balance;
        feeCollects[sender][token] = feeCollects[sender][token].add(fee);
        _allFrom.add(sender);
        _allToken.add(token);
        emit FeeCollected(sender, token, fee);
    }

    // restrict function
    function migrate(address migrator) external override onlyOwner {
        IFeeCollectorMigrator migrator_ = IFeeCollectorMigrator(migrator);
        uint256 tokenLength = _allToken.length();
        uint256 fromLength = _allFrom.length();
        for (uint256 tIndex = 0; tIndex < tokenLength; tIndex++) {
            address token = _allToken.at(tIndex);
            if (feeByTokens[token] == 0) {
                continue;
            }
            IERC20(token).approve(migrator, feeByTokens[token]);
            for (uint256 fIndex = 0; fIndex < fromLength; fIndex++) {
                address from = _allFrom.at(fIndex);
                uint256 amount = feeCollects[from][token];
                if (amount == 0) {
                    continue;
                }
                migrator_.migrate(from, token, amount);
            }
        }
    }

    function enableToken(address token, bool enable) external onlyOwner {
        require(token != address(0), "INV_TOKEN");
        enabledTokens[token] = enable;
    }

    function enableSender(address sender, bool enable) external onlyOwner {
        require(sender != address(0), "INV_SENDER");
        enabledSenders[sender] = enable;
    }
}
