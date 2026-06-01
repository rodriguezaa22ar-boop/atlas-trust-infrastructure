# Milestone 168: Reviewer Quickstart Simplification

## Reviewed Commit

`2b59caa6e9e782b1dcf6ceb37380a766a8357815` M167 merged checkpoint

## Purpose

Reduce adoption friction found in M167 by adding a simplified reviewer
quickstart for first verify, first replay, GitHub Actions metadata import,
linked replay, evidence sufficiency review, and reviewer decision summary.

M168 is the value step after the M167 adoption friction dry-run.

## Added

- Added `docs/REVIEWER_QUICKSTART.md`.
- Updated `docs/INDEX.md` to link the reviewer quickstart from starting-point,
  role, operator workflow, trust lifecycle, governance, and release trust
  sections.
- Added focused Bats coverage for quickstart commands, `prev_hash`
  explanation, evidence sufficiency warning, related reviewer docs, retention,
  and bounded claim language.
- Updated the milestone index with the M168 retention entry.

## Validation

- `git diff --check`: pass.
- Focused M168 reviewer quickstart Bats: pass.
- `./bin/export-public-trust --check`: pass.
- `nix-shell --run './bin/dev-qa'`: pass.

## Adoption Impact

M168 preserves the M167 adoption value while reducing friction:

```text
Atlas supports a simplified reviewer quickstart that gets a new reviewer from
fresh clone to first verify, first replay, GitHub Actions metadata import,
linked replay, evidence sufficiency review, and reviewer decision summary.
```

The quickstart makes `prev_hash` explicit and keeps the warning that evidence
`present` does not automatically mean evidence sufficient.

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
- Known limitations preserved.
- No compliance, certification, legal sufficiency, guaranteed safety, external
  audit completion, external SLSA certification, production deployability
  outside the local Atlas contract, complete source-event knowledge, model
  correctness, runtime safety, artifact correctness, or replacement-of-human-
  judgment claim added.
- Tag target: `atlas-retention-m168`.
