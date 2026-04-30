# Milestone 100: Release SLSA Reference Verification

## Release Commit

`99e1f2a37570ce8448bf5b358d9c301401ef9428` Add release SLSA reference verification

## Purpose

Make retained SLSA provenance references directly verifiable from Atlas instead
of only through release artifact manifest verification.

## Added

- `atlas release slsa-verify [reference] [--commit sha]`.
- Default SLSA reference discovery from
  `docs/retention/releases/*.slsa.json`.
- Read-only verification rows for schema, metadata-only flags,
  forbidden-content markers, source identity, source commit, artifact digest,
  workflow path, GitHub run URL, recorded attestation verification status,
  known limitations, and the complete retained-reference contract.
- Shared JSON forbidden-content scanning now catches `token=` markers and is
  reused by release artifact manifests and SLSA references.
- Command help, command reference, release trust docs, SLSA provenance docs,
  schema docs, roadmap, known limitations, and Atlas README updates.
- Negative tests for commit mismatch, subject digest mismatch, pending
  attestation status, forbidden token markers, and malformed SLSA JSON.

## Verified

- `bash -n tools/atlas/lib/release.sh`
- `bash -n tools/atlas/bin/atlas`
- `git diff --check`
- `nix-shell --run 'bats --filter "atlas release slsa-verify checks retained SLSA provenance references|atlas release manifest records optional SLSA provenance references|atlas release manifest indexes and verifies retained release artifacts|schema docs pin implemented Atlas JSON contracts|ci workflow mirrors local Atlas QA gate|atlas help groups target-first workflow and story commands" tests/atlas.bats'`: `6/6`
- `nix-shell --run './bin/dev-qa'`: `103/103`, lint ok, stress ok

## Repo State

- Atlas can now verify retained SLSA reference metadata locally.
- The command does not download artifacts or query GitHub.
- Atlas does not claim external SLSA certification.
- Optional online `gh attestation verify` execution remains future work.
- No target-touching behavior was added.
- No production-ready, external audit, payment verification, legal compliance,
  or third-party assurance claim is made by this milestone.
