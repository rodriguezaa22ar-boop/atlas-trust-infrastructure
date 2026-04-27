# Milestone 44: Atlas Accepted Risk Workflow

## Commit

`6a82074 Add Atlas finding acceptance workflow`

## Purpose

Make accepted-risk decisions explicit, auditable, and visible in readiness and
reports instead of relying on a generic status update.

## Added

- `atlas finding accept <id> --reason <text>`
- Required accepted-risk reason
- Accepted-risk operator and timestamp metadata
- Optional accepted-risk owner and expiry metadata
- Optional evidence and validation links on acceptance records
- Acceptance metadata preservation across later finding updates
- Report and finding-show rendering for accepted-risk context
- v1 pillar contract and blueprint updates
- Regression coverage proving acceptance unblocks readiness

## Verified

- `bash -n tools/atlas/lib/v1.sh tools/atlas/lib/findings.sh tools/atlas/lib/report.sh tools/atlas/bin/atlas`
- `git diff --check`
- `nix-shell --run 'bats tests/atlas.bats --filter "finding accept|accepted-risk|help"'`: 2/2
- `nix-shell --run 'bats tests/atlas.bats --filter "findings record|operation readiness|validation retest|operation report|v1 status"'`: 6/6
- `nix-shell --run 'bats tests/atlas.bats'`: 27/27
- `nix-shell --run './bin/dev-lint'`: lint ok
- `nix-shell --run './bin/dev-qa'`: 70/70, lint ok, stress ok

## Boundaries

This milestone adds the accepted-risk workflow but does not automatically accept
any existing live findings. Risk acceptance remains an explicit governance
decision that requires a reason and optional owner/expiry metadata.

Expiry is recorded for audit visibility but is not yet enforced automatically.

## Repo State

- implementation committed: `6a82074 Add Atlas finding acceptance workflow`
- retention note present
- tag target: `atlas-retention-m44`
