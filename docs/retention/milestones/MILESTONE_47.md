# Milestone 47: Atlas Accepted-Risk Review Queue

## Commit

`8af1dd8 Add Atlas accepted-risk review queue`

## Purpose

Make accepted-risk review workload visible before expiry blocks closeout.
Operators can now see which accepted risks are expired, due soon, missing an
expiry, or current for the active operation.

## Added

- `atlas finding review-queue [--within days]`
- Accepted-risk state classification: `expired`, `due-soon`, `no-expiry`, and
  `current`
- Configurable review window with `--within` and `--window`
- Deterministic date support through `ATLAS_TODAY`
- Queue counts plus a tabular finding view with owner, severity, level, title,
  and acceptance/review reason
- README, Atlas README, blueprint, and v1 pillar contract updates
- Regression coverage for queue states and invalid review window handling

## Verified

- `bash -n tools/atlas/lib/findings.sh tools/atlas/bin/atlas tools/atlas/lib/v1.sh`
- `git diff --check`
- `nix-shell --run 'bats tests/atlas.bats --filter "review-queue|accepted risk|expired accepted|help"'`: 3/3
- `nix-shell --run 'bats tests/atlas.bats'`: 29/29
- `nix-shell --run './bin/dev-lint'`: lint ok
- `nix-shell --run './bin/dev-qa'`: 72/72, lint ok, stress ok

## Behavior

`atlas finding review-queue` is read-only. It loads the active operation,
filters accepted findings for the active target, compares each acceptance expiry
against the current date and review window, and prints a review queue sorted by
state.

## Boundaries

This milestone does not renew, resolve, or auto-notify accepted risks. Renewal
still requires an explicit `atlas finding review` command with an owner decision
and review reason.

## Repo State

- implementation committed: `8af1dd8 Add Atlas accepted-risk review queue`
- retention note present
- tag target: `atlas-retention-m47`
