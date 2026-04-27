# Milestone 52: Atlas Release Candidate Trust-Chain Replay Verification

## Commit

`cceeecc2d8fcb5961056ac318178c2216ab8f8e7` Replay operation trust chains during release verification

## Purpose

Make release verification prove recorded operation trust-chain claims against
current retained operation state instead of trusting the release packet field by
itself.

## Added

- Operation trust-chain replay during `atlas release verify`.
- Local operation reload from a release packet's recorded operation slug.
- Recomputed trust-chain comparison for recorded status.
- Ledger event and SHA replay comparison for JSON release packets.
- Archive packet verification replay comparison for JSON release packets.
- Markdown release packet trust-chain replay for recorded operation/status
  fields.
- Negative regression coverage proving `release verify` fails after a retained
  operation artifact changes post-release-packet.
- README, Atlas CLI docs, trust lifecycle, blueprint, and v1 readiness contract
  updates.

## Behavior

Release packets without an operation trust-chain binding still verify as
`not-recorded`. Release packets with an operation binding must replay against
local retained operation state. If the operation is missing, no longer current,
or has archive/ledger replay drift, verification fails.

## Boundaries

This milestone does not add cryptographic signing, immutable storage, external
attestations, or a new release trust schema version. It strengthens local
verification by using current retained results rather than packet claims alone.

## Verified

- `bash -n tools/atlas/lib/release.sh tools/atlas/bin/atlas tests/atlas.bats`
- `git diff --check`
- Focused BATS: `2/2`
- Full BATS: `29/29`
- `nix-shell --run './bin/dev-lint'`: lint ok
- `nix-shell --run './bin/dev-qa'`: `72/72`, lint ok, stress ok

## Repo State

- Implementation committed at `cceeecc2d8fcb5961056ac318178c2216ab8f8e7`.
- Retention note present.
- Tag target: `atlas-retention-m52`.
