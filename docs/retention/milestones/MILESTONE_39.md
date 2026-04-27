# Milestone 39: Atlas Web Validation Queue

## Commit

`2fea85b Add Atlas web validation plan queue`

## Purpose

Turn open findings from `atlas web assess` into approval-gated validation
plans without requiring operators to manually translate each finding into a
validation queue item.

## Added

- `atlas web validation-plan [--all]`
- `--finding <id>` support for one explicit web assessment finding
- `--lane <lane>` support, defaulting to the bounded `posture` lane
- Highest-severity default when no finding and no `--all` are provided
- Automatic evidence linking from the original web assessment finding
- Duplicate prevention when a finding already has a validation plan
- Documentation in README, Atlas README, blueprint, and trust lifecycle
- Test coverage for queueing all web findings and skipping duplicates

## Live Smoke

Source operation:

- `execution-hub-m38-cors-live`

Command:

```bash
atlas web validation-plan --all
```

Result:

- operation: `execution-hub-m38-cors-live`
- target: `execution-hub-27.emergent.host`
- lane: `posture`
- considered findings: 5
- planned validation plans: 5
- skipped findings: 0

Generated validation plans:

- `vp_20260427T034417Z`: credentialed CORS allows probe origin
- `vp_20260427T034418Z`: HTTP origin does not redirect to HTTPS
- `vp_20260427T034418Z_02`: admin-style routes return successful responses
- `vp_20260427T034419Z`: missing browser hardening headers
- `vp_20260427T034419Z_02`: metadata routes return application HTML

Duplicate check:

```bash
atlas web validation-plan --all
```

Result:

- considered findings: 5
- planned validation plans: 0
- skipped findings: 5

Regenerated report:

- `reports/execution-hub-m39-validation-queue-report.md`

## Verified

- `bash -n tools/atlas/bin/atlas`
- `bash -n tools/atlas/lib/web.sh`
- `git diff --check`
- `nix-shell --run 'bats tests/atlas.bats --filter "web assess"'`: 2/2
- `nix-shell --run './bin/dev-test'`: 66/66
- `nix-shell --run './bin/dev-lint'`: lint ok
- `nix-shell --run './bin/dev-qa'`: 66/66, lint ok, stress ok

## Boundaries

`atlas web validation-plan` is metadata-only. It creates validation plan
records and links existing finding evidence. It does not approve plans, run
Vector, touch the target, perform new HTTP requests, or mark findings
validated/resolved.

## Repo State

- implementation committed: `2fea85b Add Atlas web validation plan queue`
- retention note committed: `b2d6db9 Record Atlas retention milestone 39`
- pushed to `origin/main`
- tagged: `atlas-retention-m39`
- repo clean and synced after milestone push
