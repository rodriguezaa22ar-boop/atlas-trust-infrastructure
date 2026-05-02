# Milestone 120: Trust Schema Freeze Candidate

## Commit

`b15545aeb09494b2e60594f44afe4a8832c4d0ba` M120: Add trust schema freeze candidate

## Purpose

Freeze the current Atlas trust schemas as v1 candidates before Atlas v1
Internal RC, while preserving clear maturity classifications and version-bump
rules for future schema changes.

## Added

- Added `docs/schemas/SCHEMA_FREEZE_CANDIDATE.md` to classify every current
  `docs/schemas/*.v1.md` contract
- Updated `docs/schemas/README.md` with freeze-candidate routing,
  classification meanings, and post-freeze versioning discipline
- Updated `docs/INDEX.md`, `docs/ATLAS_ONE_PAGE.md`,
  `docs/atlas/TRUST_OBJECT_MODEL.md`, and `docs/KNOWN_LIMITATIONS.md` so the
  freeze boundary is discoverable from the public reviewer path
- Added Bats guardrails that dynamically require every v1 schema file to be
  listed exactly once in the freeze candidate document with a valid
  classification

## Classification Summary

- `stable`: core v1 release trust, replay, manifest, production readiness,
  operation trust-chain, handoff, closeout, audit, archive, accepted-risk
  review, and external reviewer package contracts
- `retained-only`: release provenance and SLSA provenance metadata references
- `optional`: Advisor Packet Interface and Business Flow Evidence contracts
- `experimental` / `future`: no current v1 freeze-candidate schema uses these
  classifications

## Versioning Rule

After M120, field renames, field removals, field type changes, required-field
changes, status enum meaning changes, verification semantic changes,
metadata-only boundary weakening, or optional-to-required gate promotion require
versioning discipline.

Backward-compatible optional additions may remain possible when documented in
the affected schema contract and freeze record.

## Verified

- PR #11: merged.
- Public GitHub PR QA run `25243003791`: success.
- Public GitHub PR CodeQL workflow run `25243003787`: success.
- Public GitHub PR Release Trust run `25243003792`: success.
- Public GitHub main QA run `25243286613`: success.
- Public GitHub main CodeQL workflow run `25243286604`: success.
- Public GitHub main Release Trust run `25243286602`: success.
- Public GitHub Pages run `25243286273`: success.
- `git diff --check`: passed.
- Focused Bats:
  `schema docs pin implemented Atlas JSON contracts`, `schema freeze
  candidate`, `external legibility docs preserve Atlas trust boundaries`, and
  `root README stays`: 4/4.
- `nix-shell --run './bin/dev-lint'`: lint ok.
- `nix-shell --run './bin/dev-qa'`: 111/111, lint ok, stress ok.
- Post-merge `nix-shell --run './bin/dev-qa'`: 111/111, lint ok, stress ok.
- `atlas release verify docs/retention/releases/atlas-m120-trust-schema-freeze-candidate.json --commit b15545aeb09494b2e60594f44afe4a8832c4d0ba`:
  verified.
- `git tag -v atlas-production-candidate-m120`: good signature.
- `atlas release slsa-verify docs/retention/releases/atlas-v0.4.0-rc1.slsa.json`:
  verified.

## Retained Artifacts

- `docs/retention/releases/atlas-m120-trust-schema-freeze-candidate.json`
- `docs/retention/releases/atlas-m120-trust-schema-freeze-candidate.provenance.json`
- `docs/retention/releases/atlas-m120-trust-schema-freeze-candidate.manifest.json`
- `docs/retention/production/PRODUCTION_DRY_RUN_2026-05-02_M120.md`
- Signed tag: `atlas-production-candidate-m120`

## Trust Impact

Atlas now has a v1 schema freeze candidate that makes the current trust
contracts reviewable before v1 Internal RC. Future schema changes must preserve
versioning discipline instead of silently changing packet or verification
semantics.

## Boundaries

- This milestone does not claim external audit, certification, legal
  compliance, tamper-proof infrastructure, external SLSA certification,
  runtime safety proof, or production deployability proof.
- The schema freeze candidate is an internal v1 review boundary, not an
  external standards certification.
- Business Flow Evidence and Advisor schemas remain optional and non-blocking
  for core v1 and production readiness.
- Schema contracts remain metadata-only and do not embed secrets, credentials,
  tokens, private keys, session cookies, raw target data, raw customer data,
  payment data, packet captures, full request or response bodies, raw runtime
  artifacts, unredacted evidence bodies, raw invoices, raw contracts, exploit
  payloads, or unauthorized-access instructions.
