//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../interfaces/IHookCallee.sol";
import "../../interfaces/IFarmingCreator.sol";
import "../../farming/FixRewardFarming.sol";

contract StakePoolFixFarming is IHookCallee, FixRewardFarming {
    function lpProductHarvest(address user) external override {
        _claims(user, user);
    }

    function lpProductUpdate(address user) external override {
        require(_msgSender() == address(lpPool));
        _updateDebt(user);
    }
}

library FixFarmingCreatorLib {
    function createFarming(
        address rwToken,
        address lpPool,
        bytes memory bytecode,
        uint256 nonce
    ) internal returns (address farming) {
        bytes32 salt = keccak256(abi.encodePacked(rwToken, lpPool, nonce));
        assembly {
            farming := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        StakePoolFixFarming farming_ = StakePoolFixFarming(address(farming));
        farming_.initialize(rwToken, lpPool);
        farming_.transferOwnership(msg.sender);
    }
}

contract StakePoolFixFarmingCreator is IFarmingCreator {
    uint256 private nonce = 0;

    function createFarming(
        address rwToken,
        address lpPool,
        bytes calldata data
    ) external override returns (address) {
        nonce = nonce + 1;
        return
            FixFarmingCreatorLib.createFarming(
                rwToken,
                lpPool,
                type(StakePoolFixFarming).creationCode,
                nonce
            );
    }
}
