# Milestone 138: Demo Receipt Packet

## Commit

`7bca21b6e910df9dd5b28f4177a2d9ad98d9d6f6` M138 add demo receipt packet

## Purpose

Bind the public demo path to a synthetic Atlas Receipt v1 packet and replay
path without making the demo operational.

## Added

- Added `docs/demo/DEMO_RECEIPT_PACKET.md`
- Added the synthetic demo-site receipt chain under
  `examples/receipt/demo-site/`
- Added `docs/retention/demo/M138_DEMO_RECEIPT_PACKET.md`
- Updated `docs/INDEX.md`, `docs/demo/README.md`, and
  `docs/demo/DEMO_REVIEWER_RUNBOOK.md`
- Added a focused regression proving the demo receipt packet docs, examples,
  replay output, metadata flags, known limitations, canonicalization reference,
  and no-runtime boundary

## Validation

- PR #35: merged.
- Public GitHub PR QA: success.
- Public GitHub PR CodeQL: success.
- Public GitHub PR Release Trust: success.
- Public GitHub workflow analysis: success.
- Pre-M138 builder `nix-shell --run './bin/dev-qa'`: passed with 130/130
  Bats plus lint, portability, and stress.
- `git diff --check`: passed.
- Focused builder demo/receipt/canonicalization/M138 Bats filter: passed with
  9/9 tests.
- Builder `nix-shell --run './bin/dev-qa'`: passed with 131/131 Bats plus
  lint, portability, and stress.
- Post-merge builder `nix-shell --run './bin/dev-qa'`: passed with 131/131
  Bats plus lint, portability, and stress.

## Trust Impact

M138 makes the demo path reviewable as a synthetic receipt chain. Reviewers can
verify each `atlas.receipt.v1` record, replay the three-receipt demo chain, and
inspect the `atlas.receipt_replay.v1` checkpoint while preserving the
metadata-only boundary.

## Boundaries

- This milestone is docs, examples, and tests only.
- This milestone uses synthetic demo data only.
- This milestone does not add a database, server, web UI, network collector,
  agent execution, live Emergent integration, backend, persistence, hidden
  state, or production deployability claim.
- `metadata_only=true` and `raw_artifacts_embedded=false` are preserved.
- `known_limitations` and the receipt canonicalization contract are referenced.
- Tag target: `atlas-retention-m138`.
