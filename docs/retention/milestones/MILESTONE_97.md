# Milestone 97: SLSA-Verifiable Release Artifact Preparation

## Release Commit

`f49ea1a7ee612238589b60bbb5386d80111e5634` Prepare SLSA-verifiable release artifacts

## Purpose

Prepare Atlas release artifacts for GitHub/Sigstore SLSA provenance generation
and verification without claiming external SLSA certification.

## Added

- `.github/workflows/release-slsa.yml` for release-style artifact builds and
  GitHub Artifact Attestations.
- Source release artifact creation from the exact Git commit with `git archive`
  and deterministic gzip output.
- SHA-256 checksum and metadata env upload alongside the release artifact.
- Local QA and strict v1 readiness checks before artifact attestation.
- `actions/attest@v4` SLSA build provenance generation for the release artifact.
- Required OIDC and attestation permissions:
  - `contents: read`
  - `id-token: write`
  - `attestations: write`
  - `artifact-metadata: write`
- `docs/atlas/SLSA_PROVENANCE.md` to define the workflow, verification command,
  metadata boundary, non-guarantees, and next hardening.
- `docs/schemas/slsa-provenance.v1.md` to document the SLSA provenance readiness
  contract.
- README, CI, release trust, roadmap, blueprint, trust-object, schema, and known
  limitation updates that keep the SLSA posture explicit and non-overclaimed.
- Bats pins for the SLSA workflow, docs, schema, permissions, and no-certification
  language.

## Verified

- `bash -n tools/atlas/bin/atlas`
- `git diff --check`
- `nix-shell --run 'bats --filter "root README stays a concise landing page with dedicated docs|atlas trust infrastructure direction preserves metadata-first trust model|schema docs pin implemented Atlas JSON contracts|ci workflow mirrors local Atlas QA gate|external legibility docs preserve Atlas trust boundaries" tests/atlas.bats'`: `5/5`
- `nix-shell --run 'bats --filter "ci workflow mirrors local Atlas QA gate|schema docs pin implemented Atlas JSON contracts|root README stays a concise landing page with dedicated docs|atlas trust infrastructure direction preserves metadata-first trust model" tests/atlas.bats'`: `4/4`
- `nix-shell --run './bin/dev-qa'`: `101/101`, lint ok, stress ok

## Repo State

- Atlas is prepared to produce SLSA-verifiable release artifacts through GitHub
  Actions and GitHub Artifact Attestations.
- Atlas does not claim external SLSA certification.
- Verified SLSA attestation references are not yet recorded in Atlas release
  manifests.
- `atlas release slsa-verify` is not implemented yet.
- No target-touching behavior was added.
- No production-ready, external audit, payment verification, legal compliance,
  or third-party assurance claim is made by this milestone.
