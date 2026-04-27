# Atlas Schema Contracts

## Purpose

This directory records stable Atlas JSON contract documentation for implemented
schema-versioned outputs.

These files are not generated JSON Schema documents yet. They are operational
schema contracts: required fields, allowed meanings, verification rules,
metadata-only boundaries, and non-goals.

The broader actor, object, packet, freshness, verification, and replay model is
documented at [../atlas/TRUST_OBJECT_MODEL.md](../atlas/TRUST_OBJECT_MODEL.md).

## Implemented Contracts

| Schema | Surface | Contract |
| --- | --- | --- |
| `atlas.release_trust.v1` | `atlas release packet --json` | [release-trust.v1.md](release-trust.v1.md) |
| `atlas.release_provenance.v1` | `docs/retention/releases/*.provenance.json` | [release-provenance.v1.md](release-provenance.v1.md) |
| `atlas.production_readiness.v1` | `atlas production status --json` | [production-readiness.v1.md](production-readiness.v1.md) |
| `atlas.operation_trust_chain.v1` | `atlas op trust-chain --json` | [operation-trust-chain.v1.md](operation-trust-chain.v1.md) |

## Design Contracts

These contracts document planned optional modules. They are not stable command outputs yet.

| Schema | Planned Surface | Contract |
| --- | --- | --- |
| `atlas.business_flow_evidence.v1` | `atlas flow packet --json` evidence object | [business-flow-evidence.v1.md](business-flow-evidence.v1.md) |
| `atlas.business_flow_packet.v1` | `atlas flow packet --json` packet object | [business-flow-packet.v1.md](business-flow-packet.v1.md) |

## Rules

- Every schema-versioned Atlas JSON output must be documented here.
- Every documented schema must name required fields and verification rules.
- Packet-oriented schemas must remain metadata-only.
- Design contracts must be clearly marked as planned until a stable command
  emits them.
- Future JSON packet formats should be added here before being treated as
  stable release or replay inputs.

## Release Trust Consumers

- `atlas release verify` validates `atlas.release_trust.v1`.
- `atlas release replay` validates `atlas.release_trust.v1` from a detached
  checkout of the packet commit.
- Release replay verification checks `atlas.release_trust.v1` against the
  packet's recorded commit from a clean checkout.
- `atlas production status` reports `atlas.production_readiness.v1` and
  verifies `atlas.release_provenance.v1` when signing/provenance is required.
