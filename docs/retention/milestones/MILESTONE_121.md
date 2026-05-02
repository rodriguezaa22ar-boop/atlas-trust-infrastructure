# Milestone 121: Atlas v1 Internal RC

## Commit

`7b3f6f575f1acbdaa3729009564ad3b9824a556c` M121: Declare Atlas v1 Internal RC

## Purpose

Bundle the current Atlas trust-infrastructure state as the Atlas v1 Internal
Release Candidate. This milestone does not add a new feature surface; it
documents, verifies, retains, and tags the current internally reviewable RC
state.

## Added

- Added `docs/atlas/V1_INTERNAL_RC.md` to define what the v1 Internal Release
  Candidate includes and what it does not mean
- Updated `README.md`, `docs/INDEX.md`, and `docs/KNOWN_LIMITATIONS.md` so the
  RC boundary is discoverable from the public reviewer path
- Added Bats guardrails requiring the RC document to reference release trust,
  release replay JSON, production explainability, the CI Release Trust gate,
  external reviewer packages, the SLSA-verifiable release artifact candidate
  path, optional-ready Business Flow Evidence, the demo operation, the schema
  freeze candidate, known limitations, exact verification commands, and
  non-guarantees

## Verified

- PR #12: merged.
- Public GitHub PR QA run `25248396150`: success.
- Public GitHub PR CodeQL workflow run `25248396144`: success.
- Public GitHub PR Release Trust run `25248396157`: success.
- Public GitHub main QA run `25248905392`: success.
- Public GitHub main CodeQL workflow run `25248905396`: success.
- Public GitHub main Release Trust run `25248905385`: success.
- Public GitHub Pages run `25248905159`: success.
- `git diff --check`: passed.
- Focused Bats:
  `v1 internal RC doc`, `root README`, `external legibility docs preserve Atlas
  trust boundaries`, `reviewer flow polish`, `demo walkthrough`, and
  `schema freeze candidate`: 6/6.
- `nix-shell --run './bin/dev-lint'`: lint ok.
- `nix-shell --run './bin/dev-qa'`: 112/112, lint ok, stress ok.
- Post-merge `nix-shell --run './bin/dev-qa'`: 112/112, lint ok, stress ok.
- `atlas v1 status --strict`: ready.
- `atlas release verify docs/retention/releases/atlas-m121-v1-internal-rc.json --commit 7b3f6f575f1acbdaa3729009564ad3b9824a556c`:
  verified.
- `git tag -v atlas-production-candidate-m121`: good signature.
- `atlas release slsa-verify docs/retention/releases/atlas-v0.4.0-rc1.slsa.json`:
  verified.

## Retained Artifacts

- `docs/retention/releases/atlas-m121-v1-internal-rc.json`
- `docs/retention/releases/atlas-m121-v1-internal-rc.provenance.json`
- `docs/retention/releases/atlas-m121-v1-internal-rc.manifest.json`
- `docs/retention/production/PRODUCTION_DRY_RUN_2026-05-02_M121.md`
- Signed tag: `atlas-production-candidate-m121`
- RC tag: `atlas-v1-internal-rc`

## Trust Impact

Atlas now has an internally reviewable v1 Release Candidate boundary. The RC
bundles retained release evidence, release replay JSON, production
explainability, CI release-trust verification, reviewer packages, the
SLSA-verifiable release artifact candidate path, optional-ready Business Flow
Evidence, the synthetic demo operation, and the schema freeze candidate.

## Boundaries

- This milestone does not claim external audit, certification, legal
  compliance, tamper-proof infrastructure, external SLSA certification,
  runtime safety proof, or production deployability proof.
- The v1 Internal Release Candidate is an internal review boundary, not an
  external certification or public production launch.
- Business Flow Evidence remains optional-ready and non-blocking for core v1
  and production readiness.
- The SLSA-verifiable release artifact remains a candidate path and is not
  external SLSA certification.
- RC docs and retained packets remain metadata-only and do not embed secrets,
  credentials, tokens, private keys, session cookies, raw target data, raw
  customer data, payment data, bank details, packet captures, full request or
  response bodies, raw runtime artifacts, unredacted evidence bodies, raw
  invoices, raw contracts, exploit payloads, or unauthorized-access
  instructions.
