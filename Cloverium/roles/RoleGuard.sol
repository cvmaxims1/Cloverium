//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/IAccessControl.sol";

/**
 * @dev Role base guard base contract
 */
abstract contract RoleGuard {
    bytes32 public constant OWNER_ROLE = "1";
    bytes32 public constant OPERATOR_ROLE = "2";
    bytes32 public constant FARMING_CONTROL_ROLE = "3";
    bytes32 public constant SNAPSHOT_ROLE = "4";

    IAccessControl internal _roleControl;

    modifier onlyPeerOwner() {
        require(hasRole(OWNER_ROLE, _msgSender()), "OWNER_ROLE_ONLY");
        _;
    }

    modifier onlyOperator() {
        require(hasRole(OPERATOR_ROLE, _msgSender()), "OPERATOR_ONLY");
        _;
    }

    modifier onlyFarmControl() {
        require(hasRole(FARMING_CONTROL_ROLE, _msgSender()), "FARM_CONTROL_ONLY");
        _;
    }

    modifier canSnapshot() {
        require(hasRole(SNAPSHOT_ROLE, _msgSender()), "SNAPSHOT_ROLE_ONLY");
        _;
    }

    function setRoleControl(address roleControl) external {
        require(isOwner(), "INV_NOT_OWNER");
        _roleControl = IAccessControl(roleControl);
    }

    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roleControl.hasRole(role, account);
    }

    function isOwner() public view virtual returns (bool);

    function _msgSender() internal view virtual returns (address);
}
