# Milestone 164: Organization CI Release Review Workflow

## Reviewed Commit

`7644fbb0b22df62b7ba20b6ebef72c2224cfac6f` M163 merged checkpoint

## Purpose

Create a one-day organization-facing proof workflow showing how a real team
can try Atlas for one CI release review without adding live integrations.

M164 is the value step after the M163 public trust surface safety regression.
It translates the proof-to-value surface into an adoption workflow that an
operator and reviewer can run and understand in one day.

## Added

- Added `docs/workflows/ORG_CI_RELEASE_REVIEW_WORKFLOW_M164.md`.
- Updated `docs/INDEX.md` to expose the workflow from the start, role,
  operator, trust, and release-trust navigation paths.
- Added focused Bats coverage for the workflow, retention note, milestone
  index, docs index link, adoption/value language, blind spots, human process
  risks, time/cost benefit, and bounded claim language.
- Updated the milestone index with the M164 retention entry.

## Validation

- `git diff --check`: pass.
- Focused M164 organization workflow Bats: pass.
- `./bin/export-public-trust --check`: pass.
- `nix-shell --run './bin/dev-qa'`: pass.

## Trust Impact

M164 adds the positive adoption claim:

```text
Atlas supports a one-day CI release review workflow by connecting local
GitHub Actions run/check metadata receipts, evidence sufficiency status, and
reviewer decision packet outcomes.
```

This helps an organization see what Atlas makes easier: metadata-only receipt
review, linked replay, evidence sufficiency checks, decision packet outcomes,
blind spot visibility, and follow-up actions.

## Boundaries

- Docs/tests only.
- No Atlas runtime behavior changed.
- No receipt semantics changed.
- No adapter changed.
- No live integration.
- No GitHub API call.
- No webhook.
- No network collector.
- No database, server, or web UI.
- No QA, Release Trust, CodeQL, workflow analysis, production status, release
  verify, release replay, reviewer package, public export, receipt verify, or
  receipt replay gate weakened.
- No certification, external audit completion, legal compliance,
  tamper-proof infrastructure, guaranteed safety, external SLSA certification,
  production deployability outside the local Atlas contract, enterprise
  deployment approval, model correctness, runtime safety, artifact correctness,
  or complete event coverage claim added.
- Tag target: `atlas-retention-m164`.
