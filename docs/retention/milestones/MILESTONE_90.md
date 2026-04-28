# Milestone 90: Atlas Release Artifact Manifest

## Release Commit

`f418a332a68671a3e975c9a8b16771f8f7ff5d6b` Harden Atlas release manifest verification

This milestone also includes implementation commit
`249a799c9f0aa62e37d00afd12c40b62bb51c469` Add Atlas release artifact manifest.

## Purpose

Add a metadata-only release artifact manifest so retained release evidence can
be indexed and re-verified as a single local release artifact set.

## Added

- `atlas release manifest [manifest-name]`.
- `atlas release manifest-verify [manifest]`.
- JSON schema `atlas.release_artifact_manifest.v1`.
- Manifest indexing for:
  - release packet path and SHA-256
  - signed provenance packet path and SHA-256
  - retained signing public key path and SHA-256
  - production dry-run note path and SHA-256
  - signed tag name, target, and tag object
  - optional milestone note path and SHA-256
- Verification checks for:
  - schema version
  - metadata-only and no-production-overclaim flags
  - retained artifact SHA-256 hashes
  - release packet verification
  - signed provenance verification
  - production dry-run note validation
  - signed tag verification with the retained public key
  - metadata boundary and known limitations
- Deterministic release packet, provenance, and dry-run discovery so copied
  worktrees do not depend on filesystem timestamp ordering.
- Docs, schema index, packet parity, roadmap, blueprint, v1 readiness contract,
  command reference, and Atlas README updates for release artifact manifests.

## Retained Evidence

- `docs/retention/releases/atlas-m90-release-artifact-manifest.json`
- `docs/retention/releases/atlas-m90-release-artifact-manifest.provenance.json`
- `docs/retention/releases/atlas-m90-release-artifact-manifest.manifest.json`
- `docs/retention/production/PRODUCTION_DRY_RUN_2026-04-28_M90.md`
- Signed tag: `atlas-production-candidate-m90`

## Verified

- `bash -n tools/atlas/lib/release.sh tools/atlas/bin/atlas`
- `git diff --check`
- `nix-shell --run 'bats --print-output-on-failure tests/atlas.bats --filter "release manifest|schema docs pin"'`: `2/2`
- `nix-shell --run 'bats --print-output-on-failure tests/atlas.bats --filter "production status|release packet|release replay|release manifest"'`: `5/5`
- `nix-shell --run './bin/dev-qa'`: `98/98`, lint ok, stress ok
- `./tools/atlas/bin/atlas release packet atlas-m90-release-artifact-manifest --json --qa-status pass --qa-command "nix-shell --run './bin/dev-qa'" --qa-note "dev-qa passed with 98/98 tests, lint ok, and stress ok before M90 release artifact manifest packet"`
- `./tools/atlas/bin/atlas release verify docs/retention/releases/atlas-m90-release-artifact-manifest.json --commit f418a332a68671a3e975c9a8b16771f8f7ff5d6b`: verified
- `./tools/atlas/bin/atlas release replay docs/retention/releases/atlas-m90-release-artifact-manifest.json --skip-qa`: verified
- `./tools/atlas/bin/atlas release manifest-verify docs/retention/releases/atlas-m90-release-artifact-manifest.manifest.json --commit f418a332a68671a3e975c9a8b16771f8f7ff5d6b`: verified
- `git tag -v atlas-production-candidate-m90`: good signature

## Repo State

- Release commit: `f418a332a68671a3e975c9a8b16771f8f7ff5d6b`.
- Release packet retained.
- Release provenance packet retained.
- Release artifact manifest retained.
- Production dry-run note retained.
- Release artifact manifest verification is implemented.
- No production-ready claim is made beyond the local Atlas contract.
