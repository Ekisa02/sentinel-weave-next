# Sentinel Weave

Sentinel Weave is a modular Solidity project for on-chain cybersecurity threat detection and management. It provides a secure registry for threat reports, an oracle integration model for confirmations, and a lightweight scoring library to prioritize incidents. Built with Hardhat and OpenZeppelin for secure, tested, and extensible smart contract deployments.

## Architecture (high level)

- contracts/
  - ThreatRegistry.sol - Core registry storing reported threats, access-controlled operations, and event emission for off-chain ingestion.
  - ThreatOracle.sol - Minimal oracle adapter with dedicated role to confirm threats on-chain (simulating off-chain detectors/feeds).
  - ThreatScore.sol - Pure library to derive normalized risk scores from severity, confirmations and age.

- scripts/
  - deploy.js - Example deployment script for local and test networks.

- test/
  - ThreatRegistry.test.js - Comprehensive tests for role management, reporting, confirmation, resolving, and scoring.

- docs/
  - architecture.md - Extended architecture notes and integration guide.

## Features

- Role-based access control: ADMIN, REPORTER, ORACLE, ANALYST.
- Report, update, confirm, and resolve threats with immutable event logs for off-chain consumers.
- Simple, auditable risk scoring function (severity + confirmations, time decay) as a library for composability.
- Test-suite with Hardhat, ethers and chai.

## Installation

Requirements:
- Node.js 16+ (recommended 18)
- npm or yarn

1. Clone the repository

   git clone <repo-url>
   cd sentinel-weave

2. Install dependencies

   npm install

3. Compile contracts

   npx hardhat compile

4. Run tests

   npx hardhat test

## Usage

- Local development: start Hardhat node

  npx hardhat node

  In another terminal, deploy to local node:

  node scripts/deploy.js

- Interacting with contracts
  - Use Hardhat console or Ethers.js/Foundry to read events emitted by ThreatRegistry (ThreatReported, ThreatConfirmed, ThreatResolved) to build off-chain analysis pipelines.

## Security considerations

- AccessControl enforces gating of sensitive functions. Carefully manage ADMIN keys.
- On-chain storage is public. Avoid storing sensitive raw payloads; favour metadata URI pointers (IPFS) when necessary.
- The scoring function is intentionally simple and auditable; for production use, consider more sophisticated and off-chain ML driven scoring.

## Extensibility

- Plug additional oracle adapters that can call confirmThreat on ThreatRegistry.
- Add upgradability patterns (UUPS/Proxy) if governance-driven upgrades are needed.
- Extend threat schema with structured metadata or Merkle-backed proofs for compact on-chain references.

## Files of interest

- contracts/ThreatRegistry.sol
- contracts/ThreatOracle.sol
- contracts/ThreatScore.sol
- test/ThreatRegistry.test.js
- scripts/deploy.js
- docs/architecture.md

## License

MIT
