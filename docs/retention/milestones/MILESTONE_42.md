# Milestone 42: Atlas Validation Supersession

## Commit

`bdfa1de Add Atlas validation supersession`

## Purpose

Make obsolete or failed validation executions explicitly supersedable by a
successful replacement run without deleting or rewriting the original record.

## Added

- `atlas validation supersede <id> --by <replacement-id> --reason <text>`
- `atlas op validation supersede` alias through the operation validation surface
- Append-only validation records with supersession metadata
- Validation detail fields for replacement plan, supersession reason, operator,
  and timestamp
- Report and brief rendering for superseded validation plans
- Guardrails requiring the replacement plan to be executed, successful, and in
  the same operation, target, lane, and finding
- Regression coverage for failed-run replacement and report rendering
- README, Atlas README, and blueprint updates

## Live Smoke

Source operation:

- `gruyere-m41-path-target`

Command:

```bash
atlas validation supersede vp_20260427T045255Z \
  --by vp_20260427T050411Z \
  --reason "sandbox-blocked execution replaced by successful network-enabled M41 validation run"
```

Result:

- superseded validation: `vp_20260427T045255Z`
- replacement validation: `vp_20260427T050411Z`
- superseded status: `superseded`
- original result retained: `failed`
- replacement result retained: `success`
- report: `reports/gruyere-m42-supersession-report.md`
- handoff: `sessions/gruyere-m41-path-target/handoff/gruyere-m42-supersession-handoff.md`

## Verified

- `bash -n tools/atlas/bin/atlas tools/atlas/lib/validation.sh tools/atlas/lib/brief.sh`
- `git diff --check`
- `nix-shell --run 'bats tests/atlas.bats --filter "validation"'`: 4/4
- `nix-shell --run './bin/dev-test'`: 68/68
- `nix-shell --run './bin/dev-lint'`: lint ok
- `nix-shell --run './bin/dev-qa'`: 68/68, lint ok, stress ok

## Boundaries

Supersession is metadata-only. It does not delete failed validation history,
alter target evidence, rerun tools, or mark a finding resolved. It only records
that a later successful validation plan supersedes an earlier executed plan.

## Repo State

- implementation committed: `bdfa1de Add Atlas validation supersession`
- retention note present
- tag target: `atlas-retention-m42`
