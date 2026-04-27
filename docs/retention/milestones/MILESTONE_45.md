# Milestone 45: Atlas Accepted-Risk Expiry Gate

## Commit

`8e18f0c Add Atlas accepted-risk expiry gate`

## Purpose

Prevent accepted-risk findings from becoming permanent silent waivers. Atlas now
detects accepted findings whose review date has passed and requires explicit
review before clean closure.

## Added

- Expired accepted-risk detection in operation readiness
- `Expired Accepted Risks` readiness count and detail section
- Close-readiness blocker for expired accepted risks
- Audit flag output for expired accepted risks
- v1 Findings pillar warning when accepted risks are expired
- Handoff, closeout, and archive packet summaries for expired accepted risks
- `ATLAS_TODAY` test override for deterministic expiry checks
- Regression coverage for current and expired accepted-risk paths

## Verified

- `bash -n tools/atlas/lib/readiness.sh tools/atlas/lib/audit.sh tools/atlas/lib/handoff.sh tools/atlas/lib/closeout.sh tools/atlas/lib/archive.sh tools/atlas/lib/v1.sh tools/atlas/bin/atlas`
- `git diff --check`
- `nix-shell --run 'bats tests/atlas.bats --filter "accepted-risk|expired accepted|v1 status"'`: 3/3
- `nix-shell --run 'bats tests/atlas.bats --filter "finding accept|operation readiness|operation archive|trust lifecycle"'`: 4/4
- `nix-shell --run 'bats tests/atlas.bats'`: 28/28
- `nix-shell --run './bin/dev-lint'`: lint ok
- `nix-shell --run './bin/dev-qa'`: 71/71, lint ok, stress ok

## Behavior

Accepted findings remain non-blocking while no expiry is recorded or the expiry
date is still current. Once the expiry date is in the past, Atlas leaves the
finding status as `accepted` but marks close readiness as
`attention-required` and shows the finding in audit/v1 review surfaces.

## Boundaries

Atlas records and checks expiry dates, but it does not yet send scheduled
reminders before expiry. Operators must still choose whether to re-accept,
resolve, or reopen the underlying risk after review.

## Repo State

- implementation committed: `8e18f0c Add Atlas accepted-risk expiry gate`
- retention note present
- tag target: `atlas-retention-m45`
