# Milestone 114: Production Status Explainability

## Commit

`9b7682942db367aa023b103e67b6e6c418594bd5` M114: Add production status explainability

## Purpose

Make Atlas production readiness reviewer-readable by adding a human explanation
mode for the local Atlas production contract.

## Added

- `atlas production status --explain`
- `atlas production status --strict --explain`
- Reviewer-facing retained evidence paths and verification commands
- Gate detail output showing why production status is ready or not ready
- Known limitation and non-guarantee sections in explain output
- Regression coverage for:
  - passing explain output
  - not-ready explain output
  - `Strict: yes` / `Strict: no` reviewer wording
  - non-guarantee language
  - metadata-only exclusions
  - no standalone `production-ready` claim in explain output

## Verified

- PR #5: merged.
- Public GitHub PR QA run `25225121826`: success.
- Public GitHub PR CodeQL workflow run `25225121815`: success.
- `bash -n tools/atlas/lib/production.sh`: passed.
- `git diff --check`: passed.
- Focused Bats:
  `atlas production status reports conservative production blockers`: 1/1.
- `nix-shell --run './bin/dev-qa'`: 109/109, lint ok, stress ok.

## Retained Artifacts

- `docs/retention/releases/atlas-m114-production-status-explainability.json`
- `docs/retention/releases/atlas-m114-production-status-explainability.provenance.json`
- `docs/retention/releases/atlas-m114-production-status-explainability.manifest.json`
- `docs/retention/production/PRODUCTION_DRY_RUN_2026-05-01_M114.md`
- Signed tag: `atlas-production-candidate-m114`

## Trust Impact

Production status now explains the local Atlas contract in human-readable form.
Reviewers can see the retained evidence paths, verification commands, gate
reasons, known limitations, and non-guarantees without reverse-engineering the
production readiness implementation.

## Boundaries

- This milestone does not change production readiness semantics.
- Explain output is metadata-only and excludes raw runtime artifacts, secrets,
  customer data, packet captures, request or response bodies, payment data, raw
  business records, and unredacted evidence bodies.
- Explain output is a reviewer aid, not an external audit result.
- This does not claim certification, legal compliance, external SLSA
  certification, enterprise deployment approval, tamper-proof infrastructure,
  runtime safety, or production deployability outside the local Atlas contract.
