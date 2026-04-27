# Milestone 43: Atlas Validated Open Retest State

## Commit

`b005127 Promote retested Atlas findings to validated`

## Purpose

Make retest outcomes update the linked finding maturity correctly. A finding
that is retested and remains observable should be `validated/open`, not merely
`observed/open`.

## Added

- `atlas validation retest` now promotes linked findings to `validated`
- Resolved retests become `validated/resolved`
- Still-open retests become `validated/open`
- Regression coverage for still-open retest promotion
- README, Atlas README, and blueprint updates

## Live Smoke

### Local bWAPP

Updated validation retests:

- `vp_20260427T045242Z`
- `vp_20260427T045243Z`

Result:

- findings: 2 total, 0 observed, 0 inferred, 2 validated
- status: both findings remain open
- report: `reports/bwapp-m43-validated-open-report.md`
- handoff: `sessions/bwapp-local-m41-path-target/handoff/bwapp-m43-validated-open-handoff.md`

### Google Gruyere

Updated validation retests:

- `vp_20260427T045256Z`
- `vp_20260427T045256Z_02`
- `vp_20260427T045257Z`
- `vp_20260427T050411Z`

Result:

- findings: 4 total, 0 observed, 0 inferred, 4 validated
- status: all findings remain open
- superseded failed plan remains preserved: `vp_20260427T045255Z`
- report: `reports/gruyere-m43-validated-open-report.md`
- handoff: `sessions/gruyere-m41-path-target/handoff/gruyere-m43-validated-open-handoff.md`

## Verified

- `bash -n tools/atlas/bin/atlas tools/atlas/lib/validation.sh`
- `git diff --check`
- `nix-shell --run 'bats tests/atlas.bats --filter "validation"'`: 5/5
- `nix-shell --run './bin/dev-test'`: 69/69
- `nix-shell --run './bin/dev-lint'`: lint ok
- `nix-shell --run './bin/dev-qa'`: 69/69, lint ok, stress ok

## Boundaries

This milestone does not mark unresolved findings as remediated. It only records
that a validation retest confirmed the finding state. Operators must still
resolve, accept, or remediate validated/open findings before closure.

## Repo State

- implementation committed: `b005127 Promote retested Atlas findings to validated`
- retention note present
- tag target: `atlas-retention-m43`
