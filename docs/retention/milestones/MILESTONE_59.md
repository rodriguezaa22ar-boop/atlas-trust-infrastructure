# Milestone 59: Atlas Operation Trust-Chain JSON

## Commit

`fed8dcc8b16f3fa943c1a630ffa7c46751b27112` Add Atlas operation trust-chain JSON

## Purpose

Make operation trust-chain closeout state machine-readable while preserving the
existing read-only text command and strict-mode behavior.

## Added

- `atlas op trust-chain [name] [--strict] [--json]`.
- JSON schema `atlas.operation_trust_chain.v1`.
- Machine-readable operation metadata, trust-chain status, next step,
  readiness counts, v1 readiness summary, freshness states, verification
  states, artifact paths, and ledger anchor.
- Strict JSON behavior: `--strict --json` still exits nonzero unless the trust
  chain is `current`.
- Regression coverage for incomplete and current trust-chain JSON output.
- README, Atlas README, trust lifecycle, and blueprint updates.

## Behavior

The command remains read-only. JSON mode collects the same retained state as
the text trust-chain view and does not write ledger events or create packets.

## Verified

- `bash -n tools/atlas/lib/trust.sh tools/atlas/bin/atlas tests/atlas.bats`
- `git diff --check`
- `nix-shell --run 'bats tests/atlas.bats --filter "operation archive"'`: `1/1`
- `nix-shell --run 'bats tests/atlas.bats --filter "trust lifecycle"'`: `1/1`
- `nix-shell --run './bin/dev-qa'`: `76/76`, lint ok, stress ok

## Repo State

- Implementation committed at `fed8dcc8b16f3fa943c1a630ffa7c46751b27112`.
- Retention note present.
- Index updated through Milestone 59.
- Tag target: `atlas-retention-m59`.
