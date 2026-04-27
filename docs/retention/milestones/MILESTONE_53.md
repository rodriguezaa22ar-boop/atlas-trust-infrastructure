# Milestone 53: Atlas Markdown Release Trust-Chain Replay Parity

## Commit

`e5c0e0ed22a2c2c852fec4370b9ff8e1042ab5bd` Add Markdown release trust-chain replay parity

## Purpose

Give Markdown release packets the same retained-result operation replay
standard as JSON release packets.

## Added

- Markdown release packet operation ledger event count and SHA recording.
- Markdown `atlas release verify` operation ledger replay comparison.
- Markdown `atlas release verify` archive packet path and verification replay.
- Regression coverage proving Markdown release packets verify when the retained
  operation is current.
- Regression coverage proving Markdown release verification fails after retained
  operation state changes.
- README, Atlas CLI docs, trust lifecycle, blueprint, and v1 readiness contract
  updates.

## Behavior

When a Markdown release packet records an operation trust chain, release
verification now reloads the retained operation and compares the current
trust-chain status, operation ledger anchor, and archive packet replay state.
The Markdown path no longer has weaker verification than JSON for operation
trust-chain replay.

## Boundaries

This milestone does not add cryptographic signing, immutable storage, external
attestations, or a new release trust schema version. It strengthens local
verification parity between the two existing packet formats.

## Verified

- `bash -n tools/atlas/lib/release.sh tests/atlas.bats`
- `git diff --check`
- Focused BATS: `2/2`
- Full BATS: `29/29`
- `nix-shell --run './bin/dev-lint'`: lint ok
- `nix-shell --run './bin/dev-qa'`: `72/72`, lint ok, stress ok

## Repo State

- Implementation committed at `e5c0e0ed22a2c2c852fec4370b9ff8e1042ab5bd`.
- Retention note present.
- Tag target: `atlas-retention-m53`.
