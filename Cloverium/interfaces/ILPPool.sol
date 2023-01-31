//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ILPPool {
    /**
     * @dev Return total shares
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Return shares for account
     */
    function balanceOf(address account) external view returns (uint256);
}
