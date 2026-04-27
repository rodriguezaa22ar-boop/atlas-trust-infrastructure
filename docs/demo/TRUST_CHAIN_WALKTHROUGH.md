# Atlas Trust Chain Walkthrough

## Purpose

This walkthrough explains what `atlas op trust-chain` means during the demo
operation and how to read the result without treating it as production
certification.

The trust-chain view is metadata-only. It verifies retained paths, statuses,
counts, hashes, and ledger anchors instead of embedding raw operation contents.

## Trust Chain Inputs

The operation trust chain reads retained operation state:

- scope snapshot
- operation ledger
- evidence records and bundle
- findings and accepted-risk review state
- validation plans and retest outcomes
- operation report
- handoff packet
- closeout manifest
- audit packet
- archive packet
- operation-scoped v1 readiness

It does not read raw packet captures, secrets, credential material, private
keys, tokens, or unredacted evidence bodies.

## Current State Rule

`atlas op trust-chain <operation> --strict` is current only when:

- close readiness is ready
- report freshness is current
- evidence bundle freshness is current when a bundle exists
- handoff freshness is current when a handoff exists
- closeout freshness is current
- accepted-risk review packet state is current when accepted risks exist
- audit packet freshness and verification are current
- archive packet freshness and verification are current
- operation-scoped v1 readiness has no required pillar gaps

## JSON Use

Use JSON for gates, replay, and future dashboards:

```bash
./tools/atlas/bin/atlas op trust-chain demo-operation --json
```

The JSON schema is documented at:

```text
docs/schemas/operation-trust-chain.v1.md
```

Key fields:

- `schema_version`
- `status`
- `next_step`
- `readiness`
- `freshness`
- `verification`
- `artifacts`
- `ledger`

## Release Binding

When a release packet records an operation, `atlas release verify` must replay
the operation trust chain from current retained operation state. The release
packet is not trusted as a static claim.

Expected release-bound verification path:

```bash
./tools/atlas/bin/atlas op trust-chain demo-operation --strict
./tools/atlas/bin/atlas release packet demo-operation-release --json --operation demo-operation --qa-status pass
./tools/atlas/bin/atlas release verify demo-operation-release
```

## Known Limits

- Operation trust packets are hash-anchored but not individually signed.
- Replay verification is local-first and repository-backed.
- Production readiness is limited to the local contract reported by
  `atlas production status`; it is not an external audit or deployment
  certification.
