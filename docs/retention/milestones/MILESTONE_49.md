# Milestone 49: Atlas Accepted-Risk Review Packet Freshness

## Commit

`3c15fefe1b7d0d9831bfabda8ac97b0a5d6f89c7` Add Atlas accepted-risk review packet freshness

## Purpose

Make accepted-risk review packets part of the readiness, audit, and archive trust pipeline.

## Added

- Accepted-risk count in readiness output.
- Latest accepted-risk review packet tracking.
- Accepted-risk review packet freshness states: `missing`, `current`, and `stale`.
- Audit flags for missing or stale accepted-risk review packets when accepted risks exist.
- Archive snapshot and archive packet accepted-risk review packet verification state.
- Archive packet hash anchoring for the latest accepted-risk review packet.
- Regression coverage for missing, current, stale, and regenerated review packet states.
- README, Atlas CLI docs, blueprint, and v1 pillar readiness contract updates.

## Behavior

Accepted-risk review packet freshness is advisory in readiness, flagged in audit when accepted risks exist, and considered by archive snapshots and packets when accepted risks exist.

## Boundaries

This milestone does not renew, approve, or close accepted risks. Review packet generation remains an explicit operator action that records the accepted-risk review state.

## Verified

- `bash -n tools/atlas/lib/readiness.sh tools/atlas/lib/audit.sh tools/atlas/lib/archive.sh tests/atlas.bats`
- `git diff --check`
- Focused BATS: `5/5`
- Full BATS: `29/29`
- `nix-shell --run './bin/dev-lint'`
- `nix-shell --run './bin/dev-qa'`: `72/72`, lint ok, stress ok

## Repo State

- Implementation committed at `3c15fefe1b7d0d9831bfabda8ac97b0a5d6f89c7`.
- Retention note present.
- Tag target: `atlas-retention-m49`.
