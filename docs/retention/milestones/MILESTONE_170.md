# Milestone 170: Scale and Storage Strategy

## Reviewed Commit

`9d774a4f25ab2016a1032f8418e77755b8610e99` M168/M169 merged checkpoint

## Purpose

Prepare Atlas for larger receipt volumes by documenting a scale and storage
strategy before adding storage or runtime systems.

M170 is the value step after the M169 reviewer quickstart safety regression.
It keeps Atlas metadata-first, local-first, file-backed, and reviewer-friendly
while planning future receipt indexing, batch verification, batch replay,
archive manifests, checkpoints, private collector contracts, and hosted
verifier boundaries.

## Added

- Added `docs/architecture/SCALE_AND_STORAGE_STRATEGY_M170.md`.
- Updated `docs/INDEX.md` to link the strategy from starting points, roles,
  trust lifecycle, governance, release trust, and roadmap navigation.
- Added focused Bats coverage for the scale/storage strategy, retention note,
  milestone index entry, required storage topics, forbidden data categories,
  and bounded claim language.
- Updated the milestone index with the M170 retention entry.

## Validation

- `git diff --check`: pass.
- Focused M170 scale/storage Bats: pass.
- `./bin/export-public-trust --check`: pass.
- `nix-shell --run './bin/dev-qa'`: pass.

## Value

M170 gives Atlas a concrete storage strategy without jumping into a database,
server, hosted verifier, or private collector implementation. It defines how
Atlas can scale receipt storage, indexing, replay, archive rotation, batch
verification, evidence sufficiency, and reviewer queries while preserving
inspectable receipts as the source of truth.

## Boundaries

- Docs/tests only.
- No Atlas runtime behavior changed.
- No receipt semantics changed.
- No adapter changed.
- No live integration.
- No GitHub API call.
- No webhook.
- No network collector.
- No database, server, hosted verifier, private collector, web UI, or storage
  engine.
- No hidden state added.
- No QA, Release Trust, CodeQL, workflow analysis, production status, release
  verify, release replay, reviewer package, public export, receipt verify, or
  receipt replay gate weakened.
- Metadata-only and local-first boundaries preserved.
- Future storage/indexing remains subordinate to portable receipts and local
  verification.
- Known limitations preserved.
- No production storage, enterprise collector, hosted verifier, complete event
  coverage, compliance, certification, legal sufficiency, guaranteed safety,
  or replacement-of-human-judgment claim added.
- Tag target: `atlas-retention-m170`.
