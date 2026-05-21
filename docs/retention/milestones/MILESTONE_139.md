# Milestone 139: Receipt Quickstart Path

## Commit

`454fd68a32c0aae01b8c48be24e69e66ada712eb` M139 add receipt quickstart path

## Purpose

Make Atlas receipts immediately tryable by an outside reviewer in under five
minutes.

## Added

- Added `docs/TRY_RECEIPTS.md`
- Added a concise root `README.md` link to the receipt quickstart
- Updated `docs/INDEX.md`
- Added focused regressions for the quickstart path, root README concision,
  receipt verification, replay output, metadata flags, known limitations, and
  non-guarantee language

## Validation

- PR #37: merged.
- Public GitHub PR QA: success.
- Public GitHub PR CodeQL: success.
- Public GitHub PR Release Trust: success.
- Public GitHub workflow analysis: success.
- `git diff --check`: passed.
- Focused builder M139/root README/receipt Bats filter: passed with 9/9 tests.
- Builder `nix-shell --run './bin/dev-qa'`: passed with 132/132 Bats plus
  lint, portability, and stress.

## Trust Impact

M139 turns receipt verification and replay into a five-minute reviewer path.
It lets a stranger verify one demo receipt, replay the synthetic receipt chain,
inspect deterministic output, and see metadata-only and non-guarantee
boundaries before reading the full documentation set.

## Boundaries

- This milestone is docs and tests only.
- This milestone does not change runtime behavior.
- This milestone does not change receipt semantics.
- This milestone does not add demo-site runtime work.
- The root README remains concise.
- Metadata-only and non-guarantee language is preserved.
- Tag target: `atlas-retention-m139`.
