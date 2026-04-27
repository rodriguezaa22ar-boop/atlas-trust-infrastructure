# Milestone 41: Atlas Mounted Web Target Assessment

## Commit

`81a3ee8 Add Atlas mounted web target assessment`

## Purpose

Preserve the path component of a web assessment URL so Atlas can assess
mounted or path-scoped applications at their real target location instead of
probing only the host root.

## Added

- URL base-path extraction for `atlas web assess`
- Route, HTTP-origin, and API/CORS probes anchored under the input base path
- Summary packet field for the assessed base path
- Default target naming that distinguishes mounted path targets
- Regression coverage proving `/app` probes stay under `/app`
- README, trust lifecycle, and blueprint updates

## Live Smoke

### Local bWAPP

Command:

```bash
atlas web assess http://127.0.0.1:8085/bWAPP bwapp-local-m41-path-target --target bwapp-local --scope-status in-scope --criticality medium --owner Alta --timeout 10 --skip-api
atlas web validation-plan --all
```

Result:

- operation: `bwapp-local-m41-path-target`
- base path: `/bWAPP`
- findings: 2
- validation plans queued: 2
- summary: `sessions/bwapp-local-m41-path-target/web-assessment/summary.md`
- report: `reports/bwapp-local-m41-path-target-web-report.md`

### Google Gruyere

Command:

```bash
atlas web assess https://google-gruyere.appspot.com/678853114350905002375877399139933339897/ gruyere-m41-path-target --target google-gruyere-678853 --scope-status in-scope --criticality medium --owner "Google Gruyere training lab" --timeout 15 --skip-api
atlas web validation-plan --all
```

Result:

- operation: `gruyere-m41-path-target`
- base path: `/678853114350905002375877399139933339897`
- findings: 4
- validation plans queued: 4
- summary: `sessions/gruyere-m41-path-target/web-assessment/summary.md`
- report: `reports/gruyere-m41-path-target-web-report.md`

## Verified

- `bash -n tools/atlas/bin/atlas tools/atlas/lib/web.sh`
- `bash -n /home/ao/labs/bwapp/start.sh /home/ao/labs/bwapp/status.sh /home/ao/labs/bwapp/stop.sh`
- `git diff --check`
- `nix-shell --run 'bats tests/atlas.bats --filter "web assess"'`: 3/3
- `nix-shell --run './bin/dev-test'`: 67/67
- `nix-shell --run './bin/dev-lint'`: lint ok
- `nix-shell --run './bin/dev-qa'`: 67/67, lint ok, stress ok

## Boundaries

This milestone keeps Atlas bounded to metadata-first route/header and optional
API/CORS posture checks. It does not add crawling, fuzzing, exploitation, brute
forcing, or content extraction beyond retained local response artifacts.

## Repo State

- implementation committed: `81a3ee8 Add Atlas mounted web target assessment`
- retention note present
- tag target: `atlas-retention-m41`
