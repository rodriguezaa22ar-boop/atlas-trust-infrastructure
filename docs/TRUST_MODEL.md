# Atlas Trust Model

## Purpose

Atlas is a shell-native control plane for authorized security assessment
workflows and a metadata-first trust control plane for business-flow evidence.
Its trust model is based on scope, operator control, file-backed records,
metadata-only packets, and replayable verification.

Atlas does not ask an operator to trust a claim because Atlas printed it. A
claim is useful only when Atlas can point to commands, retained artifacts,
hashes, ledger events, tests, and known limitations.

## Trust Anchors

- authorized target records
- operation scope snapshots
- append-only `ledger.ndjson` events
- evidence records and SHA-256 hashes
- metadata-only business-flow records and evidence links
- finding lifecycle records
- approval-gated validation records
- operation reports
- metadata-only handoff, closeout, audit, archive, and release packets
- signed release provenance packets
- v1 readiness and production readiness gates
- milestone retention notes and tags

## Verification Pattern

Trust artifacts should support at least one of these:

- freshness check
- hash verification
- ledger event count check
- schema/version check
- metadata-only guardrail
- replay verification from retained local state
- signed tag verification
- known limitation disclosure

## Current Boundaries

Atlas is internally ready for testing, refinement, and release-trust hardening.
It is not production-certified, externally audited, cryptographically
immutable, tamper-proof, or enterprise-ready.

Production readiness requires release signing/provenance, retained production
dry-run evidence or external validation evidence, and a current verified
release trust packet to exist together. Passing that local contract is not an
external audit or deployment certification.

The strategic direction is documented in
[atlas/TRUST_INFRASTRUCTURE_DIRECTION.md](atlas/TRUST_INFRASTRUCTURE_DIRECTION.md).
