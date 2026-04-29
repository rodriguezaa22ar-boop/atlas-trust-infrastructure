# Milestone 95: Operation Business Flow Assurance Rollup

## Release Commit

`e6ae7d6874eb31b21b8ccba40590d9ff98a99bd1` Add business flow assurance rollup to op trust-chain

## Purpose

Promote optional Business Flow Evidence from per-flow assurance to operation
trust-chain visibility by adding aggregate assurance rollups to
`atlas op trust-chain` and its JSON schema while keeping the feature read-only,
metadata-only, and non-blocking.

## Added

- Operation trust-chain text assurance counts for linked business flows.
- JSON `business_flow_evidence.assurance` rollup.
- Metadata-only per-flow assurance summaries in operation trust-chain JSON.
- Matching packet counts across retained Markdown and JSON flow packets.
- Schema documentation for aggregate flow assurance fields.
- Trust lifecycle documentation noting aggregate flow assurance counts.
- Bats coverage proving text output, JSON output, schema pins, and read-only
  ledger behavior.

## Verified

- `bash -n tools/atlas/lib/trust.sh`
- `bash -n tools/atlas/bin/atlas`
- `git diff --check`
- `nix-shell --run 'bats --filter "atlas op trust-chain surfaces business-flow evidence context read-only|schema docs pin implemented Atlas JSON contracts" tests/atlas.bats'`: `2/2`
- `nix-shell --run './bin/dev-qa'`: `100/100`, lint ok, stress ok

## Repo State

- Business Flow Evidence remains optional and non-blocking.
- Operation trust-chain rollups are aggregate and metadata-only.
- No target-touching behavior was added.
- No production-ready, external audit, payment verification, legal compliance,
  or third-party assurance claim is made by this milestone.
