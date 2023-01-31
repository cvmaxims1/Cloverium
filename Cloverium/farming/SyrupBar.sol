//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/farming/ISyrupBar.sol";
import "../libraries/TransferHelper.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @dev User must send token to syrup_bar before mint function get called otherwise failed to mint
 */
contract SyrupBar is ISyrupBar, Ownable {
    using SafeMath for uint256;

    address internal _token;

    /**
     * @dev mint token
     */
    function initialize(address token) external onlyOwner {
        require(token != address(0), "INV_TOKEN");
        require(_token == address(0), "INV_TOKEN_SET");
        _token = token;
    }

    function mint(address to, uint256 amount) external virtual override onlyOwner {
        TransferHelper.safeTransfer(_token, to, amount);
    }

    function migrate(address migrator) external onlyOwner {
        IERC20 token = IERC20(_token);
        uint256 amount = token.balanceOf(address(this));
        token.approve(migrator, amount);
        ISyrupBarMigrator(migrator).migrate(amount);
    }
}

/**
 * @dev IOU syrup_bar only mint no more than token balance that syrup hold
 */
contract IOUSyrupBar is SyrupBar {
    function mint(address to, uint256 amount) external override onlyOwner {
        uint256 balance = IERC20(_token).balanceOf(address(this));
        TransferHelper.safeTransfer(_token, to, balance < amount ? balance : amount);
    }
}
