//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract GovernorRoles is AccessControl {
    bytes32 public constant OWNER_ROLE = "1";
    bytes32 public constant OPERATOR_ROLE = "2";
    bytes32 public constant FARMING_CONTROL_ROLE = "3";
    bytes32 public constant SNAPSHOT_ROLE = "4";

    constructor() {
        // update role admin
        _setRoleAdmin(OWNER_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(OPERATOR_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(FARMING_CONTROL_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(SNAPSHOT_ROLE, DEFAULT_ADMIN_ROLE);

        // grant roles to owner
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(OWNER_ROLE, msg.sender);
        _grantRole(OPERATOR_ROLE, msg.sender);
        _grantRole(FARMING_CONTROL_ROLE, msg.sender);
        _grantRole(SNAPSHOT_ROLE, msg.sender);
    }
}
