//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../interfaces/IFarmingCreator.sol";
import "../../interfaces/IHookCallee.sol";
import "../../farming/SyrupBarFarming.sol";
import "../../farming/SyrupBar.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract StakePoolSyrupFarming is IHookCallee, SyrupBarFarming {
    function lpProductHarvest(address user) external override {
        _safeClaims(user, user);
    }

    function lpProductUpdate(address user) external override {
        require(_msgSender() == address(lpPool));
        _updateDebt(user);
    }
}

library SyrupFarmingCreator {
    function createFarming(
        address rwToken,
        address lpPool,
        bytes memory data,
        bytes memory bytecode,
        uint256 nonce
    ) internal returns (address farming) {
        address syrup = createSyrup(rwToken, nonce);
        bytes32 salt = keccak256(abi.encodePacked(rwToken, lpPool, nonce));
        assembly {
            farming := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }

        (uint256 rewardPerBlock, uint256 startBlock, uint256 duration) = abi.decode(
            data,
            (uint256, uint256, uint256)
        );
        address farming_ = address(farming);
        StakePoolSyrupFarming farming__ = StakePoolSyrupFarming(farming_);
        farming__.initialize(rwToken, syrup, lpPool, rewardPerBlock, startBlock, duration);
        farming__.transferOwnership(msg.sender);
        SyrupBar(syrup).transferOwnership(farming_);
    }

    function createSyrup(address rwToken, uint256 nonce) internal returns (address syrup) {
        bytes memory bytecode = type(IOUSyrupBar).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(rwToken, nonce));
        assembly {
            syrup := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        SyrupBar syrup_ = SyrupBar(syrup);
        syrup_.initialize(rwToken);
    }
}

contract StakePoolSyrupFarmingCreator is IFarmingCreator {
    uint256 private nonce = 0;

    function createFarming(
        address rwToken,
        address lpPool,
        bytes calldata data
    ) external override returns (address farming) {
        nonce = nonce + 1;
        farming = SyrupFarmingCreator.createFarming(
            rwToken,
            lpPool,
            data,
            type(StakePoolSyrupFarming).creationCode,
            nonce
        );
    }
}
