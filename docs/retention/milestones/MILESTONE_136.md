# Milestone 136: Atlas Failure-Mode Map

## Commit

`8c46749fa39b254e8ce960544954ad375a32ff61` M136 add Atlas failure-mode map

## Purpose

Make Atlas failure modes visible early by mapping common startup failure
lessons to Atlas-specific trust, review, documentation, and boundary risks.

## Added

- Added `docs/strategy/ATLAS_FAILURE_MODE_MAP.md`
- Linked the failure-mode map from `docs/INDEX.md`
- Documented Atlas-specific risks for claim drift, proof theater, private-state
  leakage, feature spread, authority without accountability, optimistic status
  text, unsafe receipts, read-only mutation, stale retained evidence,
  portability overclaims, AI boundary confusion, and buried negative evidence
- Documented safeguard classes for language, state, commands, repository
  boundaries, and review practice
- Added design-pressure questions for future Atlas ideas

## Validation

- PR #30: merged.
- Public GitHub PR QA: success.
- Public GitHub PR CodeQL: success.
- Public GitHub PR Release Trust: success.
- Public GitHub workflow analysis: success.
- `git diff --check`: passed.
- Focused builder docs Bats filter: passed.
- Post-merge builder `nix-shell --run './bin/dev-qa'`: passed with 128/128
  Bats plus lint, portability, and stress.

## Trust Impact

M136 keeps Atlas strategy tied to bounded claims and retained verification
instead of product theater. It makes future feature pressure reviewable before
implementation, especially around receipts, release trust, demos, production
readiness, AI advisor boundaries, and public/private repository separation.

## Boundaries

- This milestone is docs-only strategy work.
- This milestone does not add runtime behavior.
- This milestone does not add tools, scanners, listeners, collectors, CI/CD
  integration, ticketing workflow, GRC workflow, or agent autonomy.
- This milestone does not change verifier behavior or receipt semantics.
- This milestone does not start demo packet work.
- Tag target: `atlas-retention-m136`.
