# Milestone 167: Adoption Friction Dry-Run

## Reviewed Commit

`7a5d30cd9742d41fe5846c0d891ab25447f33222` M166 merged checkpoint

## Purpose

Create a retained adoption friction dry-run that tests whether a new reviewer
or operator can follow Atlas' one-day CI release review workflow and understand
the result without live help from the builder.

M167 is the hardening/adoption-test step after M166. It checks usability,
clarity, command friction, output friction, evidence sufficiency understanding,
reviewer decision support, and known-limitations visibility.

## Added

- Added `docs/reviews/ADOPTION_FRICTION_DRY_RUN_M167.md`.
- Updated `docs/INDEX.md` to link the retained adoption dry-run.
- Added focused Bats coverage for the dry-run path, references, commands,
  expected outputs, friction log, scorecard, known limitations, unsupported
  decisions, and claim boundaries.
- Updated the milestone index with the M167 retention entry.

## Validation

- `git diff --check`: pass.
- Focused M167 adoption friction Bats: pass.
- `./bin/export-public-trust --check`: pass.
- `nix-shell --run './bin/dev-qa'`: pass.

## Adoption Impact

M167 preserves the adoption value introduced by M164 and M166:

```text
Atlas supports a retained one-day CI release review dry-run that helps a new
reviewer reach first verify, first replay, evidence sufficiency review,
plain-English summary, and reviewer decision support without live explanation
from the builder.
```

The dry-run records friction honestly with a `warning` result rather than
pretending external validation has happened.

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
- This is a retained internal dry-run, not an external usability study.
- Known limitations preserved.
- No market adoption, external user success, compliance, certification, legal
  sufficiency, guaranteed safety, external audit completion, external SLSA
  certification, production deployability outside the local Atlas contract,
  complete event coverage, missed-event detection, model correctness, runtime
  safety, artifact correctness, or absence-of-action-outside-Atlas claim added.
- Tag target: `atlas-retention-m167`.
