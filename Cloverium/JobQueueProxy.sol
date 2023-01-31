//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./libraries/EIP712.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
 * @dev proxy contract to emit job event on user behalf
 */
contract JobQueueProxy is EIP712 {
    event JobQueued(address indexed sender, uint256 indexed job, bytes data);

    bytes32 private immutable _PERMIT_TYPEHASH =
        keccak256("EnqueueBySig(address sender,uint256 job,uint256 deadline,bytes data)");

    constructor() EIP712("RRB", "1", 1001) {}

    function enqueue(uint256 job, bytes calldata data) external {
        _enqueue(msg.sender, job, data);
    }

    function enqueueBySig(
        address sender,
        uint256 job,
        uint256 deadline,
        bytes calldata data,
        bytes calldata signature
    ) external {
        require(block.timestamp <= deadline, "EXP_DEADLINE");
        bytes32 structHash = keccak256(abi.encode(_PERMIT_TYPEHASH, sender, job, deadline, data));
        address signer = ECDSA.recover(_hashTypedDataV4(structHash), signature);
        require(signer == sender, "INV_SIGNATURE");
        _enqueue(sender, job, data);
    }

    function _enqueue(
        address sender,
        uint256 job,
        bytes calldata data
    ) internal {
        require(!Address.isContract(sender), "INV_NOT_A_CONTRACT");
        emit JobQueued(sender, job, data);
    }
}
