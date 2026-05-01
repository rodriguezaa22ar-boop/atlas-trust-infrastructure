# Milestone 113: Release Replay JSON Status

## Commit

`0dda2159e7033d67c9599d0fd827e0167349a2e1` Merge pull request #4 from rodriguezaa22ar-boop/m113-release-replay-hardening

## Purpose

Harden release replay by adding machine-readable, metadata-only replay status
for future CI, reviewer package, and release-trust consumers.

## Added

- `atlas release replay --json`
- `atlas.release_replay.v1` schema contract
- Full commit resolution before replay checkout/reporting
- Release trust documentation for replay JSON
- Schema index, docs index, command reference, and help output updates
- Regression coverage for:
  - replay JSON status
  - metadata-only replay boundary
  - non-guarantee language
  - schema documentation
  - help output

## Verified

- PR #4: merged.
- Public GitHub PR QA run `25210404581`: success.
- Public GitHub PR CodeQL run `25210404580`: success.
- `bash -n tools/atlas/lib/release.sh`: passed.
- `bash -n tools/atlas/bin/atlas`: passed.
- `git diff --check`: passed.
- Focused Bats:
  `release replay checks release packet from replay worktree`: 1/1.
- Focused Bats:
  `schema docs pin implemented Atlas JSON contracts`: 1/1.
- Focused Bats:
  `atlas help groups target-first workflow and story commands`: 1/1.
- `nix-shell --run './bin/dev-qa'`: 109/109, lint ok, stress ok.

## Retained Artifacts

- `docs/retention/releases/atlas-m113-release-replay-json-status.json`
- `docs/retention/releases/atlas-m113-release-replay-json-status.provenance.json`
- `docs/retention/releases/atlas-m113-release-replay-json-status.manifest.json`
- `docs/retention/production/PRODUCTION_DRY_RUN_2026-05-01_M113.md`
- Signed tag: `atlas-production-candidate-m113`

## Trust Impact

Atlas release replay now has a stable machine-readable status surface. Replay
results can be consumed by future gates and reviewer tooling without parsing
human text output or embedding command logs.

## Boundaries

- This milestone does not add target-touching behavior.
- Replay JSON is metadata-only and excludes QA logs, raw runtime artifacts,
  target evidence, secrets, customer data, packet captures, and raw business
  records.
- `--skip-qa` remains weaker than full replay and is explicitly recorded as
  `skipped`.
- This does not claim external audit, certification, legal compliance, external
  SLSA certification, enterprise deployment approval, or tamper-proof
  infrastructure.
