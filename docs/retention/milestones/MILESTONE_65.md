# Milestone 65: Atlas Retained Production Dry-Run Gate

## Commit

`cd257b18692b20410a271469caedce16e845d764` Add retained production dry-run gate

## Purpose

Turn the production dry-run gate from a hard-coded blocker into a real retained
evidence check.

## Added

- Production dry-run note discovery under `docs/retention/production/`.
- Required production dry-run note fields.
- Commit matching for the current commit or the retained release commit before
  the dry-run retention commit.
- Production readiness documentation updates.
- Roadmap and blueprint updates.
- Production-status tests for missing and retained dry-run evidence.
- Retained dry-run note:
  `docs/retention/production/PRODUCTION_DRY_RUN_2026-04-27.md`.

## Behavior

`atlas production status` now marks `Production Dry Run` ready only when the
latest `PRODUCTION_DRY_RUN_*.md` note has the required fields and matches the
current release commit or the immediate parent release commit.

Production readiness remains `not-ready` until all required gates are ready.
Signing/provenance and release packet freshness are still expected blockers.

## Verified

- `bash -n tools/atlas/lib/production.sh`
- `git diff --check`
- `nix-shell --run 'bats --filter "production status" tests/atlas.bats'`: `1/1`
- `nix-shell --run './bin/dev-qa'`: `81/81`, lint ok, stress ok
- `./tools/atlas/bin/atlas v1 status --strict`: ready
- `./tools/atlas/bin/atlas production status`: not-ready

## Repo State

- Implementation committed at `cd257b18692b20410a271469caedce16e845d764`.
- Production dry-run note retained.
- Retention note present.
- Index updated through Milestone 65.
- Tag target: `atlas-retention-m65`.
