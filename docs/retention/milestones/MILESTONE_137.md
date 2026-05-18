# Milestone 137: Receipt Canonicalization Contract

## Commit

`4ef6674c79330b7ec5af3453fd6d311b6d7fb859` M137 add receipt canonicalization contract

## Purpose

Freeze how Atlas computes Receipt v1 hashes so reviewers can reproduce receipt
verification deterministically across machines.

## Added

- Added `docs/schemas/receipt-canonicalization.v1.md`
- Updated `docs/RECEIPTS.md` with canonicalization rules
- Updated `docs/schemas/README.md` and `docs/INDEX.md`
- Updated `docs/schemas/SCHEMA_FREEZE_CANDIDATE.md` with the receipt
  canonicalization classification
- Added golden-vector tests for `examples/receipt/minimal.json`
- Added tests proving whitespace and object key order changes do not alter
  computed hashes
- Added tests proving semantic field changes and array-order changes alter
  computed hashes
- Added tests documenting which fields are excluded during `event_hash` and
  `receipt_hash` computation

## Validation

- PR #33: merged.
- Public GitHub PR QA: success.
- Public GitHub PR CodeQL: success.
- Public GitHub PR Release Trust: success.
- Public GitHub workflow analysis: success.
- `git diff --check`: passed.
- Focused builder receipt/canonicalization/schema-freeze Bats filter: passed
  with 7/7 tests.
- Builder `nix-shell --run './bin/dev-qa'`: passed with 130/130 Bats plus
  lint, portability, and stress.

## Trust Impact

M137 makes Receipt v1 hashing replayable by reviewers without private runtime
state. It freezes the local `jq -cS` canonical byte stream, the
`event_hash` excluded fields, the `receipt_hash` excluded field, and the
non-guarantees around receipt verification.

## Boundaries

- This milestone is docs and tests only.
- This milestone does not change receipt runtime semantics.
- This milestone does not weaken verifier language.
- This milestone does not add a database, server, network behavior, or
  demo-site work.
- Metadata-only, `known_limitations`, and raw-artifact rejection behavior are
  preserved.
- Tag target: `atlas-retention-m137`.
