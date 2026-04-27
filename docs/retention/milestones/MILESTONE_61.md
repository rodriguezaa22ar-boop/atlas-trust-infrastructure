# Milestone 61: Atlas Trust Schema Contracts

## Commit

`d036759f266f00daa31989ebacdb02ed35f56d1c` Document Atlas JSON schema contracts

## Purpose

Stabilize documentation for implemented schema-versioned Atlas JSON contracts
before adding more packet JSON formats.

## Added

- `docs/schemas/README.md`.
- `docs/schemas/release-trust.v1.md`.
- `docs/schemas/production-readiness.v1.md`.
- `docs/schemas/operation-trust-chain.v1.md`.
- Schema links from packet format parity documentation.
- README, Atlas README, blueprint, and Bats coverage for schema contracts.

## Hardened

- Readiness freshness comparisons now use ledger line order as a tie-breaker
  when events share the same second-level timestamp.
- The accepted-risk freshness regression now forces a same-second report/review
  sequence to prove later ledger events still make retained reports stale.

## Behavior

This milestone does not add a new JSON packet surface. It documents the JSON
contracts Atlas already emits and hardens freshness ordering for fast local
execution.

## Verified

- `bash -n tools/atlas/lib/readiness.sh`
- `git diff --check`
- `nix-shell --run 'bats --filter "schema docs" tests/atlas.bats'`: `1/1`
- `nix-shell --run 'bats --filter "packet format parity" tests/atlas.bats'`: `1/1`
- `nix-shell --run 'bats --filter "expired accepted risks" tests/atlas.bats'`: `1/1`
- `nix-shell --run './bin/dev-qa'`: `78/78`, lint ok, stress ok

## Repo State

- Implementation committed at `d036759f266f00daa31989ebacdb02ed35f56d1c`.
- Retention note present.
- Index updated through Milestone 61.
- Tag target: `atlas-retention-m61`.
