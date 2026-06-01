# Milestone 171: Scale and Storage Safety Regression

## Reviewed Commit

`875c503e2ca3e4075c10a595b0e1562f7928cc97` M170 scale and storage strategy

## Purpose

Protect the M170 scale and storage strategy from drifting into production
storage readiness claims, hidden database authority, raw sensitive data
storage, complete event coverage, or weakened receipt verification and replay
boundaries.

M171 is the hardening step after the M170 scale and storage value step.

## Added

- Added focused Bats coverage for local-first, file-backed, inspectable receipt
  boundaries.
- Added focused checks for metadata-only storage rules and forbidden raw data
  categories.
- Added focused checks for future private collector and hosted verifier
  boundaries.
- Added focused checks preserving receipt verify, replay, canonicalization,
  release trust, reviewer package, and evidence sufficiency boundaries.
- Added focused checks preventing storage overclaims while preserving M170's
  forward-looking indexing, deduplication, archive, compression, batch
  verification, batch replay, reviewer query, and future milestone value.
- Updated the milestone index with the M171 retention entry.

## Validation

- `git diff --check`: pass.
- Focused M171 scale/storage safety Bats: pass.
- `./bin/export-public-trust --check`: pass.
- `nix-shell --run './bin/dev-qa'`: pass.

## Safety Result

M171 keeps M170 useful and forward-looking while preserving file-backed truth,
metadata-only receipts, exportable local verification, replay boundaries, and
honest storage limitations.

## Boundaries

- Docs/tests only.
- No Atlas runtime behavior changed.
- No database implementation.
- No SQLite migration.
- No server.
- No hosted verifier implementation.
- No private collector implementation.
- No new storage engine.
- No receipt semantics changed.
- No adapter changed.
- No live integration.
- No network collector.
- No web UI.
- No hidden state added.
- No QA, Release Trust, CodeQL, workflow analysis, production status, release
  verify, release replay, reviewer package, public export, receipt verify,
  receipt replay, or canonicalization gate weakened.
- Known limitations preserved.
- No production storage readiness, enterprise-scale storage implementation,
  immutable storage, tamper-proof infrastructure, complete event coverage,
  compliance, certification, legal sufficiency, guaranteed safety, raw artifact
  preservation, or database-backed production readiness claim added.
- Tag target: `atlas-retention-m171`.
