# Milestone 99: SLSA References In Release Artifact Manifests

## Release Commit

`53256e8b551b3e9b1e872d2369194dd734034a5d` Add SLSA references to release manifests

## Purpose

Allow Atlas release artifact manifests to record optional, metadata-only,
verified SLSA provenance references without making SLSA mandatory and without
claiming external SLSA certification.

## Added

- `atlas release manifest --slsa <reference>` for explicitly attaching a
  retained `atlas.slsa_provenance.v1` reference.
- Optional `slsa_provenance` manifest block with reference path, SHA-256,
  source commit, workflow identity, artifact digest, attestation URLs, and
  verification command metadata.
- Optional `slsa_provenance` artifact class in
  `atlas.release_artifact_manifest.v1`.
- `atlas release manifest-verify` checks for SLSA reference file existence,
  SLSA reference hash, schema version, verification status, commit match,
  artifact digest match, workflow path, matching optional artifact entry, and
  parity between embedded manifest metadata and the referenced SLSA file.
- Release packet discovery now excludes `*.slsa.json` references so SLSA
  references cannot be mistaken for release trust packets.
- Release manifest docs, schema docs, SLSA provenance docs, command reference,
  roadmap, known limitations, and Atlas README updates.
- Negative tests for invalid SLSA verification state, missing SLSA artifact
  entry, and tampered embedded SLSA metadata.

## Verified

- `bash -n tools/atlas/lib/release.sh`
- `bash -n tools/atlas/bin/atlas`
- `git diff --check`
- `nix-shell --run 'bats --filter "atlas release manifest records optional SLSA provenance references|atlas release manifest indexes and verifies retained release artifacts|atlas release manifest verification fails closed on completeness gaps|schema docs pin implemented Atlas JSON contracts|atlas help groups target-first workflow and story commands" tests/atlas.bats'`: `5/5`
- `nix-shell --run './bin/dev-qa'`: `102/102`, lint ok, stress ok

## Repo State

- SLSA references are optional, metadata-only, and non-blocking.
- Release artifact manifests can now retain verified SLSA provenance reference
  metadata when provided.
- Atlas does not claim external SLSA certification.
- `atlas release slsa-verify` is not implemented yet.
- No target-touching behavior was added.
- No production-ready, external audit, payment verification, legal compliance,
  or third-party assurance claim is made by this milestone.
