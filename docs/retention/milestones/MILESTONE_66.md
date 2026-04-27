# Milestone 66: Atlas Current Release Trust Packet

## Commit

`fb3017b200bc7ce9b636105308dfcaa21d26e3b1` Record Atlas retention milestone 65

## Purpose

Retain a current JSON release trust packet and matching production dry-run note
for the same release commit.

## Added

- `docs/retention/releases/atlas-m66-current.json`.
- `docs/retention/production/PRODUCTION_DRY_RUN_2026-04-27_M66.md`.
- Release verification now accepts short/full commit comparisons.
- Release verification checks retention notes from the expected packet commit
  instead of requiring notes added after that commit.
- Milestone index entry for Milestone 66.
- Blueprint entry for Milestone 66.

## Behavior

This milestone refreshes retained release evidence and hardens historical
release verification. A release packet for a parent release commit can now be
verified from a later checkout without failing on retention notes that did not
exist at the packet commit.

## Verified

- `nix-shell --run './bin/dev-qa'`: `81/81`, lint ok, stress ok
- `bash -n tools/atlas/lib/release.sh`
- `git diff --check`
- `nix-shell --run 'bats --filter "release packet" tests/atlas.bats'`: `1/1`
- `./tools/atlas/bin/atlas release packet atlas-m66-current --json --qa-status pass --qa-note "dev-qa passed before M66 release packet"`
- `./tools/atlas/bin/atlas release verify docs/retention/releases/atlas-m66-current.json`: verified
- `./tools/atlas/bin/atlas release verify docs/retention/releases/atlas-m66-current.json --commit fb3017b200bc7ce9b636105308dfcaa21d26e3b1`: verified

## Repo State

- Release commit: `fb3017b200bc7ce9b636105308dfcaa21d26e3b1`.
- Release packet retained.
- Production dry-run note retained.
- Historical release packet verification hardened.
- Retention note present.
- Index updated through Milestone 66.
- Tag target: `atlas-retention-m66`.
