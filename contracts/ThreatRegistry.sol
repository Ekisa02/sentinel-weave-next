// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./ThreatScore.sol";

/// @title ThreatRegistry
/// @notice Simple registry for cybersecurity threat reporting, confirmations and resolution
contract ThreatRegistry is AccessControl {
    using Counters for Counters.Counter;
    Counters.Counter private _idCounter;

    bytes32 public constant REPORTER_ROLE = keccak256("REPORTER_ROLE");
    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");
    bytes32 public constant ANALYST_ROLE = keccak256("ANALYST_ROLE");

    struct Threat {
        uint256 id;
        address reporter;
        string source; // free-form short origin (scanner name, IP, etc.)
        uint8 severity; // 0-10
        string metadataURI; // pointer to rich metadata (IPFS, S3)
        uint8 confirmations; // number of confirms
        bool resolved;
        uint256 timestamp;
        uint256 updatedAt;
    }

    mapping(uint256 => Threat) private threats;

    event ThreatReported(uint256 indexed id, address indexed reporter, string source, uint8 severity, string metadataURI);
    event ThreatConfirmed(uint256 indexed id, address indexed oracle, uint8 confirmations);
    event ThreatUpdated(uint256 indexed id, address indexed updater);
    event ThreatResolved(uint256 indexed id, address indexed resolver);

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /// @notice Report a new threat. Caller must have REPORTER_ROLE.
    function reportThreat(string calldata source, uint8 severity, string calldata metadataURI) external onlyRole(REPORTER_ROLE) returns (uint256) {
        require(severity <= 10, "severity out of range");
        _idCounter.increment();
        uint256 id = _idCounter.current();
        threats[id] = Threat({
            id: id,
            reporter: msg.sender,
            source: source,
            severity: severity,
            metadataURI: metadataURI,
            confirmations: 0,
            resolved: false,
            timestamp: block.timestamp,
            updatedAt: block.timestamp
        });
        emit ThreatReported(id, msg.sender, source, severity, metadataURI);
        return id;
    }

    /// @notice Confirm a threat from an oracle/aggregator. Increments confirmation count.
    function confirmThreat(uint256 id) external onlyRole(ORACLE_ROLE) {
        Threat storage t = threats[id];
        require(t.id != 0, "unknown threat");
        t.confirmations += 1;
        t.updatedAt = block.timestamp;
        emit ThreatConfirmed(id, msg.sender, t.confirmations);
    }

    /// @notice Update metadata or severity (analyst or reporter can update)
    function updateThreatMetadata(uint256 id, uint8 severity, string calldata metadataURI) external {
        Threat storage t = threats[id];
        require(t.id != 0, "unknown threat");
        require(!t.resolved, "threat resolved");
        // reporter or analyst or admin
        require(msg.sender == t.reporter || hasRole(ANALYST_ROLE, msg.sender) || hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "not authorized");
        require(severity <= 10, "severity out of range");
        t.severity = severity;
        t.metadataURI = metadataURI;
        t.updatedAt = block.timestamp;
        emit ThreatUpdated(id, msg.sender);
    }

    /// @notice Resolve a threat (analyst or admin)
    function resolveThreat(uint256 id) external {
        Threat storage t = threats[id];
        require(t.id != 0, "unknown threat");
        require(hasRole(ANALYST_ROLE, msg.sender) || hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "not authorized");
        t.resolved = true;
        t.updatedAt = block.timestamp;
        emit ThreatResolved(id, msg.sender);
    }

    /// @notice Get full threat record
    function getThreat(uint256 id) external view returns (
        uint256,
        address,
        string memory,
        uint8,
        string memory,
        uint8,
        bool,
        uint256,
        uint256
    ) {
        Threat storage t = threats[id];
        require(t.id != 0, "unknown threat");
        return (
            t.id,
            t.reporter,
            t.source,
            t.severity,
            t.metadataURI,
            t.confirmations,
            t.resolved,
            t.timestamp,
            t.updatedAt
        );
    }

    /// @notice Read-only convenience for inline scoring (0-100)
    function getThreatScore(uint256 id) external view returns (uint8) {
        Threat storage t = threats[id];
        require(t.id != 0, "unknown threat");
        uint256 age = block.timestamp - t.timestamp;
        return ThreatScore.compute(t.severity, t.confirmations, age);
    }
}
