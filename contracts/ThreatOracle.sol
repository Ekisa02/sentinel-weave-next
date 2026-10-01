// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./ThreatRegistry.sol";

/// @title ThreatOracle
/// @notice Example oracle adapter that holds ORACLE_ROLE in the registry and can confirm threats
contract ThreatOracle is AccessControl {
    bytes32 public constant ORACLE_ADMIN_ROLE = keccak256("ORACLE_ADMIN_ROLE");
    ThreatRegistry public registry;

    constructor(address registryAddress) {
        registry = ThreatRegistry(registryAddress);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ORACLE_ADMIN_ROLE, msg.sender);
    }

    /// @notice Confirm a threat in the registry. This contract must have ORACLE_ROLE granted in the registry.
    function confirm(uint256 id) external onlyRole(ORACLE_ADMIN_ROLE) {
        // calls into registry which enforces ORACLE_ROLE
        registry.confirmThreat(id);
    }
}
