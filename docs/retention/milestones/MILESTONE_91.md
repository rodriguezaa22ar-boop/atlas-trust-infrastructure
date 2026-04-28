# Milestone 91: Production Release Artifact Manifest Gate

## Release Commit

`b5b5c97e9d2dd3aabe5cb28bc03bc8494ab74a4e` Require release artifact manifest for production status

## Purpose

Make release artifact manifests part of the Atlas local production-readiness
contract. A release can no longer report `production-ready` unless the retained
release artifact manifest verifies alongside the release packet, signed
provenance, retained signing key, signed tag, and production dry-run note.

## Added

- Required `Release Artifact Manifest` gate in `atlas production status`.
- `atlas.production_readiness.v1` JSON output now includes
  `release_artifact_manifest`.
- Production status verifies the latest `atlas.release_artifact_manifest.v1`
  manifest against the current commit or retained release commit immediately
  before a manifest-retention commit.
- Deterministic release artifact manifest discovery by path sorting.
- Production status tests covering missing, blocked, and ready manifest states.
- README, Atlas README, production-readiness, release-trust, schema, packet
  parity, lifecycle, roadmap, command reference, and blueprint updates.

## Retained Evidence

- `docs/retention/releases/atlas-m91-production-manifest-gate.json`
- `docs/retention/releases/atlas-m91-production-manifest-gate.provenance.json`
- `docs/retention/releases/atlas-m91-production-manifest-gate.manifest.json`
- `docs/retention/production/PRODUCTION_DRY_RUN_2026-04-28_M91.md`
- Signed tag: `atlas-production-candidate-m91`

## Verified

- `bash -n tools/atlas/lib/production.sh`
- `bash -n tools/atlas/lib/release.sh`
- `git diff --check`
- `nix-shell --run 'bats --print-output-on-failure tests/atlas.bats --filter "production status|release manifest"'`: `2/2`
- `nix-shell --run 'bats --print-output-on-failure tests/atlas.bats --filter "production status|release manifest|packet format parity|schema docs|atlas docs index|command reference"'`: `4/4`
- `nix-shell --run './bin/dev-qa'`: `98/98`, lint ok, stress ok
- `./tools/atlas/bin/atlas release verify docs/retention/releases/atlas-m91-production-manifest-gate.json --commit b5b5c97e9d2dd3aabe5cb28bc03bc8494ab74a4e`: verified
- `./tools/atlas/bin/atlas release replay docs/retention/releases/atlas-m91-production-manifest-gate.json --skip-qa`: verified
- `./tools/atlas/bin/atlas release manifest-verify docs/retention/releases/atlas-m91-production-manifest-gate.manifest.json --commit b5b5c97e9d2dd3aabe5cb28bc03bc8494ab74a4e`: verified
- `git tag -v atlas-production-candidate-m91`: good signature

## Repo State

- Release commit: `b5b5c97e9d2dd3aabe5cb28bc03bc8494ab74a4e`.
- Release packet retained.
- Release provenance packet retained.
- Release artifact manifest retained.
- Production dry-run note retained.
- `atlas production status` requires release artifact manifest verification.
- Production readiness remains a local Atlas contract, not external audit,
  SLSA certification, deployment certification, or legal compliance.
