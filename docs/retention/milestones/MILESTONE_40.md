# Milestone 40: Atlas Web Validation Approval

## Commit

`db49735 Add Atlas web validation approval`

## Purpose

Add a web-specific approval gate for queued web validation plans so planning,
approval, execution, and retest stay separated and auditable.

## Added

- `atlas web validation-approve [--all] --reason <text>`
- `--plan <id>` support for one explicit web validation plan
- Default approval of the first planned web validation item
- Bulk approval of every planned web validation item with `--all`
- Duplicate approval protection for already approved or executed plans
- Required approval reason capture
- Documentation in README, Atlas README, blueprint, and trust lifecycle
- Test coverage for bulk approval and duplicate approval skipping

## Live Smoke

Source operation:

- `execution-hub-m38-cors-live`

Command:

```bash
atlas web validation-approve --all --reason "approved bounded web validation for M40"
```

Result:

- operation: `execution-hub-m38-cors-live`
- target: `execution-hub-27.emergent.host`
- considered validation plans: 5
- approved validation plans: 5
- skipped validation plans: 0

Approved validation plans:

- `vp_20260427T034417Z`
- `vp_20260427T034418Z`
- `vp_20260427T034418Z_02`
- `vp_20260427T034419Z`
- `vp_20260427T034419Z_02`

Duplicate check:

```bash
atlas web validation-approve --all --reason "approved bounded web validation for M40"
```

Result:

- considered validation plans: 5
- approved validation plans: 0
- skipped validation plans: 5

Regenerated report:

- `reports/execution-hub-m40-validation-approval-report.md`

Report state:

- validation planned: 0
- validation approved: 5
- validation executed: 0
- next step: run the approved validation plan and record resulting evidence

## Verified

- `bash -n tools/atlas/bin/atlas`
- `bash -n tools/atlas/lib/web.sh`
- `git diff --check`
- `nix-shell --run 'bats tests/atlas.bats --filter "web assess"'`: 2/2
- `nix-shell --run './bin/dev-test'`: 66/66
- `nix-shell --run './bin/dev-lint'`: lint ok
- `nix-shell --run './bin/dev-qa'`: 66/66, lint ok, stress ok

## Boundaries

`atlas web validation-approve` is metadata-only. It records approval state,
approval reason, and operator identity. It does not run validation, touch the
target, perform HTTP requests, or mark findings validated/resolved.

## Repo State

- implementation committed: `db49735 Add Atlas web validation approval`
- retention note present
- tag target: `atlas-retention-m40`
