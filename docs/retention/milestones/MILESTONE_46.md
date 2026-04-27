# Milestone 46: Atlas Accepted-Risk Review Workflow

## Commit

`7dd0907 Add Atlas accepted-risk review workflow`

## Purpose

Give accepted-risk renewal its own governance command instead of relying on a
generic finding update. Operators can now explicitly re-review an accepted
finding, renew owner/expiry metadata, and leave a dedicated ledger trail.

## Added

- `atlas finding review <id> --reason <text>`
- Review command limited to findings already in `accepted` status
- Required review reason
- Optional owner, expiry, evidence, and validation links for review records
- `review_reason`, `reviewed_at`, and `reviewed_by` metadata on finding records
- Dedicated `finding.reviewed` ledger event
- Finding show, report, handoff, and v1 command references updated for review
- Regression coverage proving an expired accepted risk can be renewed to ready

## Verified

- `bash -n tools/atlas/lib/findings.sh tools/atlas/lib/report.sh tools/atlas/lib/readiness.sh tools/atlas/lib/v1.sh tools/atlas/bin/atlas`
- `git diff --check`
- `nix-shell --run 'bats tests/atlas.bats --filter "help|accepted-risk|expired accepted|finding accept"'`: 3/3
- `nix-shell --run 'bats tests/atlas.bats --filter "v1 status|operation readiness|operation archive|trust lifecycle|findings record"'`: 7/7
- `nix-shell --run 'bats tests/atlas.bats'`: 28/28
- `nix-shell --run './bin/dev-lint'`: lint ok
- `nix-shell --run './bin/dev-qa'`: 71/71, lint ok, stress ok

## Behavior

`atlas finding review` fails on non-accepted findings. For accepted findings, it
appends a new lifecycle record, records review metadata, and emits
`finding.reviewed`. If the review renews an expired `accepted_until` date, the
accepted risk no longer blocks readiness after the operation report is refreshed.

## Boundaries

This milestone does not automatically decide whether a risk should be renewed.
It gives the operator a structured command for recording that decision.

## Repo State

- implementation committed: `7dd0907 Add Atlas accepted-risk review workflow`
- retention note present
- tag target: `atlas-retention-m46`
