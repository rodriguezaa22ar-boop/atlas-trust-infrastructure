# Milestone 58: Atlas Release Replay Verification Guidance

## Commit

`cc8e97616fc917b74434d7404fa1a9bab53aeb6e` Document Atlas release replay verification

## Purpose

Define how to verify a retained release trust packet from a clean checkout of
the release commit recorded inside the packet.

## Added

- `docs/retention/releases/REPLAY_VERIFICATION.md`.
- JSON release replay procedure using `git worktree add --detach`.
- Markdown release replay procedure using the packet `Commit:` field.
- Replay checklist for packet path, commit, checkout, v1 readiness, full QA,
  release verification, limitations, and failures.
- Failure policy for historical packets.
- README, Atlas README, trust lifecycle, production readiness, and blueprint
  references.
- Bats validation that preserves the clean-checkout replay procedure and
  boundaries.

## Behavior

This milestone does not change runtime command behavior.

It documents the correct replay shape for older release packets: verify from a
temporary worktree checked out at the packet commit, while passing the retained
packet by absolute path. That avoids applying newer milestone expectations to a
historical release packet that could not have known about later retained notes.

## Boundaries

Replay verification remains local verification. It does not add cryptographic
signing, external provenance, SLSA attestation, immutable storage, or a
production-ready claim.

## Verified

- `git diff --check`
- `nix-shell --run 'bats tests/atlas.bats --filter "release replay verification"'`: `1/1`
- `nix-shell --run './bin/dev-qa'`: `76/76`, lint ok, stress ok

## Repo State

- Implementation committed at `cc8e97616fc917b74434d7404fa1a9bab53aeb6e`.
- Retention note present.
- Index updated through Milestone 58.
- Tag target: `atlas-retention-m58`.
