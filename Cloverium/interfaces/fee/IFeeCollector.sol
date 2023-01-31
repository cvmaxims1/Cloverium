//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFeeCollectorMigrator {
    function migrate(
        address from,
        address token,
        uint256 fee
    ) external;
}

interface IFeeCollector {
    event FeeCollected(address indexed from, address indexed token, uint256 fee);

    function feeCollects(address from, address token) external view returns (uint256);

    function feeByTokens(address token) external view returns (uint256);

    function collect(address token) external;

    function migrate(address migrator) external;
}
