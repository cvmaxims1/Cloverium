//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";

contract BatchProcess {
    function multicall(address[] calldata targets, bytes[] calldata data)
        external
        returns (bytes[] memory results)
    {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            results[i] = Address.functionCall(targets[i], data[i]);
        }
        return results;
    }
}
