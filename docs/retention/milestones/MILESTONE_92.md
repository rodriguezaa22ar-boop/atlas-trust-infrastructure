# Milestone 92: Release Artifact Manifest Replay and Completeness

## Release Commit

`fad01270eb507c5021c0cf95a97b0be6a019fee0` Harden release artifact manifest verification

## Purpose

Harden release artifact manifests so they are not just retained indexes, but
fail-closed completeness contracts for the local Atlas release trust chain.

## Added

- `docs/atlas/RELEASE_ARTIFACT_MANIFEST.md`.
- Manifest contract references in generated `atlas.release_artifact_manifest.v1`
  JSON:
  - schema document reference
  - guidance document reference
  - known limitations reference
- `atlas release manifest-verify` checks for:
  - forbidden raw-content markers
  - manifest generation commit availability
  - signed tag metadata and target
  - artifact count
  - required artifact classes
  - required artifact paths
  - schema and guidance document references
  - known limitations reference
  - retained artifact SHA-256 hashes
  - release packet verification
  - signed provenance verification
  - production dry-run verification
  - signed tag verification
- Negative tests proving manifest verification fails for missing artifacts,
  wrong hashes, missing provenance, missing dry-run notes, commit mismatch,
  nonexistent referenced files, forbidden raw-content markers, and missing
  known limitations.
- README, documentation index, release-trust docs, production-readiness docs,
  schema docs, roadmap, and blueprint updates.

## Retained Evidence

- `docs/retention/releases/atlas-m92-release-manifest-completeness.json`
- `docs/retention/releases/atlas-m92-release-manifest-completeness.provenance.json`
- `docs/retention/releases/atlas-m92-release-manifest-completeness.manifest.json`
- `docs/retention/production/PRODUCTION_DRY_RUN_2026-04-28_M92.md`
- Signed tag: `atlas-production-candidate-m92`

## Verified

- `bash -n tools/atlas/lib/release.sh`
- `git diff --check`
- `nix-shell --run 'bats --print-output-on-failure tests/atlas.bats --filter "root README|schema docs pin|release manifest"'`: `4/4`
- `nix-shell --run './bin/dev-qa'`: `99/99`, lint ok, stress ok
- `./tools/atlas/bin/atlas release verify docs/retention/releases/atlas-m92-release-manifest-completeness.json --commit fad01270eb507c5021c0cf95a97b0be6a019fee0`: verified
- `./tools/atlas/bin/atlas release replay docs/retention/releases/atlas-m92-release-manifest-completeness.json --skip-qa`: verified
- `./tools/atlas/bin/atlas release manifest-verify docs/retention/releases/atlas-m92-release-manifest-completeness.manifest.json --commit fad01270eb507c5021c0cf95a97b0be6a019fee0`: verified
- `git tag -v atlas-production-candidate-m92`: good signature

## Repo State

- Release commit: `fad01270eb507c5021c0cf95a97b0be6a019fee0`.
- Release packet retained.
- Release provenance packet retained.
- Hardened release artifact manifest retained.
- Production dry-run note retained.
- Production readiness remains a local Atlas contract, not external audit,
  SLSA certification, deployment certification, or legal compliance.
