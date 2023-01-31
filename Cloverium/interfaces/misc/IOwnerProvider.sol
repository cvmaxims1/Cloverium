//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOwnerProvider {
    /**
     * @dev Returns the address of the current owner.
     */
    function owner() external view returns (address);
}
