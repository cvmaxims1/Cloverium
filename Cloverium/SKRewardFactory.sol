//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IFarmingCreator.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SKRewardFactory is Ownable {
    event FarmingCreated(address indexed strategy, address indexed reward, address farming);

    mapping(address => bool) internal _enableStrategies;

    function enableStrategy(address strategy, bool enable) external onlyOwner {
        require(strategy != address(0));
        _enableStrategies[strategy] = enable;
    }

    function createFarming(
        address strategy,
        address rwToken,
        address lpPool,
        bytes calldata data
    ) external onlyOwner returns (address) {
        require(_enableStrategies[strategy], "NOT_ENABLED");
        require(rwToken != address(0), "INV_TOKEN");
        require(lpPool != address(0), "INV_POOL");

        address farming = IFarmingCreator(strategy).createFarming(rwToken, lpPool, data);
        require(farming != address(0), "CREATE_FAILED");
        address sender = _msgSender();
        (bool success, ) = farming.call(
            abi.encodeWithSignature("transferOwnership(address)", sender)
        );
        require(success, "GRANT_FAILED");
        emit FarmingCreated(strategy, rwToken, farming);
        return farming;
    }
}
