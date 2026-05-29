# Milestone 155: Trust Claim Safety Repo Hygiene Hardening

## Reviewed Commit

`bae34cfb6dc16cf2e1f78c619a688126257f1424` M154 merged checkpoint

## Purpose

Harden Atlas' public trust surface after M154 introduced the Trust Claim
Ladder.

## Added

- Pinned the remaining mutable GitHub Actions refs in `.github/workflows/qa.yml`.
- Pinned the CodeQL workflow's checkout and `github/codeql-action` refs to
  immutable commits.
- Added `.github/dependabot.yml` for GitHub Actions version update proposals.
- Added a pull request template with validation and boundary checks.
- Added issue templates for bug reports and trust-claim documentation issues.
- Added `CODE_OF_CONDUCT.md`.
- Updated CI, README, contributing, security, and public export docs for the
  new repo hygiene surface.
- Added focused Bats coverage for M155 repo hygiene, workflow pins, templates,
  Code of Conduct, retention, and trust-claim language boundaries.

## Validation

- Atlas Node pre-check: Current State Ready, 0 blockers, 0 warnings; W012
  self-test passed, 25/25.
- `git diff --check`: pass.
- Focused M155/repo hygiene/trust claim Bats: pass, 2/2.
- `./bin/export-public-trust --check`: pass.
- `nix-shell --run './bin/dev-qa'`: pass.

## Trust Impact

M155 protects the post-M154 proof-to-value surface by making the public
repository's contribution, issue, conduct, Dependabot, and workflow-hardening
expectations explicit.

The milestone addresses the open CodeQL unpinned-action alert for
`cachix/install-nix-action@v31` in the QA workflow and keeps CodeQL scoped to
GitHub Actions workflow analysis without adding runtime product behavior.

## Boundaries

- Repo hygiene and docs/tests only.
- No Atlas runtime behavior changed.
- No receipt semantics changed.
- No new adapter.
- No live integration.
- No network collector.
- No database, server, or web UI.
- No QA, Release Trust, CodeQL, or workflow analysis gate weakened.
- No trust-claim boundaries removed.
- No certification, external audit completion, legal compliance,
  tamper-proof infrastructure, guaranteed safety, or model correctness claim
  added.
- Tag target: `atlas-retention-m155`.
