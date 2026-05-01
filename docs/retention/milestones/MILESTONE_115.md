# Milestone 115: CI Release Trust Gate

## Commit

`587f11ce672b9ac6035ff68b6effe86aadc62f2e` M115: Add CI release trust gate

## Purpose

Add a GitHub Actions release-trust gate that verifies the latest retained
Atlas release evidence in CI without changing production readiness semantics
or treating every source commit as a production candidate.

## Added

- `.github/workflows/release-trust.yml`
- Full-history and tag-aware retained-evidence checkout
- Temporary retained-release worktree at the latest `atlas-retention-m*` tag
- Synthetic `origin/release-trust-retained` upstream for production-status
  parity inside the retained worktree
- Release packet verification in CI
- Release artifact manifest verification in CI
- Release replay JSON verification in CI
- Signed production-candidate tag verification in CI
- Production status explainability verification in CI
- Immutable commit-SHA pinning for third-party GitHub Actions used by the
  release-trust workflow
- CI documentation and Bats guardrails for the retained-evidence gate and
  no-overclaim boundary

## Verified

- PR #6: merged.
- Public GitHub PR QA run `25230477985`: success.
- Public GitHub PR CodeQL workflow run `25230477951`: success.
- Public GitHub PR Release Trust run `25230477958`: success.
- Public GitHub main QA run `25232855359`: success.
- Public GitHub main CodeQL workflow run `25232855392`: success.
- Public GitHub main Release Trust run `25232855361`: success.
- Public GitHub Pages run `25232855004`: success.
- `nix-shell -p actionlint --run 'actionlint .github/workflows/release-trust.yml'`: passed.
- `git diff --check`: passed.
- Focused Bats:
  `ci workflow mirrors local Atlas QA gate`: 1/1.
- Local retained release-trust emulation against `atlas-retention-m114`: passed.
- `nix-shell --run './bin/dev-qa'`: 109/109, lint ok, stress ok.

## Retained Artifacts

- `docs/retention/releases/atlas-m115-ci-release-trust-gate.json`
- `docs/retention/releases/atlas-m115-ci-release-trust-gate.provenance.json`
- `docs/retention/releases/atlas-m115-ci-release-trust-gate.manifest.json`
- `docs/retention/production/PRODUCTION_DRY_RUN_2026-05-01_M115.md`
- Signed tag: `atlas-production-candidate-m115`

## Trust Impact

Atlas now has a public CI gate that continuously verifies the latest retained
release-trust evidence chain. The gate verifies retained release packet,
manifest, replay JSON, signed tag, and production explain output from a
retained-release worktree rather than requiring every pull request or source
commit to become a production candidate.

## Boundaries

- This milestone does not change Atlas production readiness semantics.
- The Release Trust workflow is an automated retained-evidence verification
  signal, not external audit or certification.
- The workflow does not claim legal compliance, tamper-proof infrastructure,
  enterprise deployment approval, external SLSA certification, runtime safety,
  or production deployability.
- The workflow verifies metadata-only retained artifacts and does not embed raw
  runtime artifacts, secrets, customer data, packet captures, request or
  response bodies, payment data, raw business records, or unredacted evidence
  bodies.
