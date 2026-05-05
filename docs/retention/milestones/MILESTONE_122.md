# Milestone 122: External RC Review Validation

## Commit

`1e57da3024bba9c55fa52e028ec3ac79cf7660d1` M122: Clarify external review boundary

## Purpose

Record the external review validation path for the retained Atlas v1 Internal
RC. This milestone makes the clean-clone reviewer workflow, retained-evidence
commands, production explainability boundary, reviewer package check, and
signed-tag portability path discoverable without changing Atlas runtime
behavior.

## Added

- Added `docs/retention/reviews/ATLAS_V1_INTERNAL_RC_EXTERNAL_REVIEW.md` as a
  metadata-only external review validation record for the retained Atlas v1
  Internal RC
- Updated `docs/INDEX.md` so the external review validation is reachable from
  the public documentation index
- Added a Bats guardrail requiring the review record to preserve clean clone,
  lab node, v1 Internal RC, retained evidence, metadata-only, reviewer package,
  signed-tag portability, and non-overclaiming language
- Clarified that `atlas production status --strict --explain` is expected to
  pass against retained release evidence, and may correctly report `not-ready`
  on active feature branches or dirty worktrees whose current commit does not
  match retained release evidence
- Clarified the terminal-first HP-to-Surface cockpit validation boundary:
  Atlas records metadata-only evidence and verification state, but does not
  operate the lab or autonomously control the dual-node setup

## Verified

- Branch: `m122-external-rc-review-validation`
- Surface builder role: terminal-first `atlas-builder` over SSH/tmux
- `nix-shell --run './bin/dev-qa'`: 113/113, lint ok, stress ok
- `./tools/atlas/bin/atlas v1 status --strict`: ready
- `./tools/atlas/bin/atlas production status --strict --explain`: correctly
  returned `not-ready` on commit `1e57da3` because retained M121 release trust
  evidence verifies the retained release commit, not the current active M122
  branch commit

## Retained Artifacts

- `docs/retention/reviews/ATLAS_V1_INTERNAL_RC_EXTERNAL_REVIEW.md`
- `docs/retention/milestones/MILESTONE_122.md`
- `docs/retention/MILESTONE_INDEX.md`
- Retention tag: `atlas-retention-m122`

## Trust Impact

Atlas now has an explicit external review validation record for the v1 Internal
RC that another reviewer can follow from a clean clone. The record improves
reviewability while preserving the boundary between retained release evidence
and live development validation.

The milestone also documents an important trust behavior: production
explainability should not overclaim readiness for a branch commit that has not
itself been retained as the production candidate.

## Boundaries

- This milestone does not change Atlas runtime behavior.
- This milestone does not create a new production candidate or supersede the
  retained M121 release evidence.
- This milestone does not claim external audit, certification, legal
  compliance, tamper-proof infrastructure, external SLSA certification,
  runtime safety proof, or production deployability proof.
- The review record is metadata-only and does not embed secrets, credentials,
  tokens, private keys, session cookies, raw target data, raw customer data,
  payment data, bank details, packet captures, full request or response bodies,
  raw runtime artifacts, unredacted evidence bodies, raw invoices, raw
  contracts, exploit payloads, or unauthorized-access instructions.
