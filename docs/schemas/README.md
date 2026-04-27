# Atlas Schema Contracts

## Purpose

This directory records stable Atlas JSON contract documentation for implemented
schema-versioned outputs.

These files are not generated JSON Schema documents yet. They are operational
schema contracts: required fields, allowed meanings, verification rules,
metadata-only boundaries, and non-goals.

## Implemented Contracts

| Schema | Surface | Contract |
| --- | --- | --- |
| `atlas.release_trust.v1` | `atlas release packet --json` | [release-trust.v1.md](release-trust.v1.md) |
| `atlas.production_readiness.v1` | `atlas production status --json` | [production-readiness.v1.md](production-readiness.v1.md) |
| `atlas.operation_trust_chain.v1` | `atlas op trust-chain --json` | [operation-trust-chain.v1.md](operation-trust-chain.v1.md) |

## Rules

- Every schema-versioned Atlas JSON output must be documented here.
- Every documented schema must name required fields and verification rules.
- Packet-oriented schemas must remain metadata-only.
- Future JSON packet formats should be added here before being treated as
  stable release or replay inputs.
