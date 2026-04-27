# Milestone 50: Atlas Operation Trust-Chain Closeout

## Commit

`bc6320a52304c7cee7b6f9a948f76928b194d7bc` Add Atlas operation trust-chain closeout

## Purpose

Provide a single read-only operation closeout check that proves whether the
readiness, accepted-risk review, closeout, audit, archive, and v1 readiness
chain is current.

## Added

- `atlas op trust-chain [name] [--strict]`.
- Read-only trust-chain status: `current`, `incomplete`, or
  `attention-required`.
- Archive packet verification inside the final trust-chain check.
- Operation-scoped v1 readiness summary inside the trust-chain view.
- Strict mode that exits nonzero unless the operation trust chain is current.
- Regression coverage for incomplete, current, and tampered trust-chain states.
- README, Atlas CLI docs, trust lifecycle, blueprint, and v1 readiness contract
  updates.

## Behavior

The trust-chain command consolidates existing Atlas evidence instead of writing
a new operation artifact. This keeps the latest archive packet from becoming
stale just because the final trust-chain check was run.

## Boundaries

This milestone does not add cryptographic signing, immutable storage, or a new
release provenance format. Release trust remains handled by
`atlas release packet` and `atlas release verify`.

## Verified

- `bash -n tools/atlas/lib/trust.sh tools/atlas/bin/atlas tests/atlas.bats`
- `git diff --check`
- Focused BATS: `5/5`
- Full BATS: `29/29`
- `nix-shell --run './bin/dev-lint'`: lint ok
- `nix-shell --run './bin/dev-qa'`: `72/72`, lint ok, stress ok

## Repo State

- Implementation committed at `bc6320a52304c7cee7b6f9a948f76928b194d7bc`.
- Retention note present.
- Tag target: `atlas-retention-m50`.
