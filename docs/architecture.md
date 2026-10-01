# Sentinel Weave — Architecture Details

This document expands on the design decisions and how to integrate Sentinel Weave into your monitoring pipeline.

## Goals

- Provide a minimal on-chain primitive for threat telemetry collection, confirmability, and prioritization.
- Keep core logic auditable and composable.
- Allow off-chain consumers to subscribe to event streams and maintain richer state and analysis pipelines.

## Components

1. ThreatRegistry (Core)
   - Stores threat records (id, reporter, severity, meta URI, confirmations, resolved, timestamp).
   - Access control roles:
     - DEFAULT_ADMIN_ROLE: governance or multisig
     - REPORTER_ROLE: detectors or scanners that can report new threats
     - ORACLE_ROLE: trusted confirmation feeds that can confirm/augment threat reports
     - ANALYST_ROLE: analysts who can update or resolve threats
   - Emits events for external indexing.

2. ThreatOracle (Adapter)
   - Lightweight adapter that holds ORACLE_ROLE and can confirm threats in the registry.
   - Intended as an example; real oracles will validate off-chain telemetry before calling the registry.

3. ThreatScore (Library)
   - Stateless library that computes a normalized risk score using severity (0-10), confirmations, and age.
   - Intended to be used by off-chain consumers or on-chain dashboards.

## Data Flow

- Detector (REPORTER_ROLE) calls reportThreat -> ThreatReported event emitted.
- Off-chain pipeline sees ThreatReported and may queue further analysis.
- An oracle or aggregator (ORACLE_ROLE) calls confirmThreat to increment confirmations -> ThreatConfirmed event.
- Analysts (ANALYST_ROLE) can resolve or update threat status -> ThreatResolved/ThreatUpdated.
- Off-chain scoring uses ThreatScore library logic (or calls a read-only method) to prioritize handling.

## Integration Patterns

- Index events with Thegraph or custom indexer to build a detailed view of threats over time.
- Use IPFS or secure off-chain stores for rich metadata; store only URIs on-chain.
- Mirror confirmations from multiple oracles for higher confidence.

## Limitations

- On-chain operations are public and cost gas: keep payloads minimal.
- This repo demonstrates a starting model. Production systems should add governance, multisig controls, and possibly on-chain dispute resolution.
