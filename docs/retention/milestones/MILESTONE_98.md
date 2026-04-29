# Milestone 98: SLSA Release Artifact Smoke Verification

## Release Commit

`087579936838faf7a5c8e3a242fd27f90ded88d5` Avoid tag refetch in SLSA branch prep

## Purpose

Prove the SLSA release artifact workflow can run from a release-style tag,
perform Atlas QA and strict readiness, build a source artifact, upload artifact
metadata, and create a GitHub/Sigstore Build Provenance attestation.

## Added

- Release commit resolution with `${GITHUB_SHA}^{commit}` so annotated tags and
  direct commit refs build from the underlying Git commit.
- Tag-triggered branch context hardening:
  - release tag commit must match `origin/main`
  - QA runs from a local `main` branch tracking `origin/main`
  - branch prep fetches only `origin/main` to avoid clobbering existing tags
- Metadata now records both the resolved release commit and original
  `GITHUB_SHA`.
- SLSA docs, schema docs, CI docs, roadmap, known limitations, and blueprint
  now describe the tag-context and smoke-verified state.
- Bats pins for release commit resolution, `ATLAS_RELEASE_COMMIT`, explicit
  `origin/main` fetch, and tag-context hardening.

## Verified

- `git diff --check`
- `nix-shell --run 'bats --filter "ci workflow mirrors local Atlas QA gate|schema docs pin implemented Atlas JSON contracts" tests/atlas.bats'`: `2/2`
- `nix-shell --run 'bats --filter "ci workflow mirrors local Atlas QA gate" tests/atlas.bats'`: `1/1`
- `nix-shell --run './bin/dev-qa'`: `101/101`, lint ok, stress ok
- GitHub `QA` workflow for `087579936838faf7a5c8e3a242fd27f90ded88d5`: success
- GitHub Pages build for `087579936838faf7a5c8e3a242fd27f90ded88d5`: success
- GitHub `Release SLSA Provenance` workflow run:
  `https://github.com/rodriguezaa22ar-boop/atlas-trust-infrastructure/actions/runs/25128727308`
  - tag: `atlas-release-m101-slsa-smoke`
  - status: success
  - `dev-qa`: `101/101`, lint ok, stress ok
  - `atlas v1 status --strict`: ready
  - artifact uploaded:
    `atlas-trust-infrastructure-atlas-release-m101-slsa-smoke-087579936838.tar.gz`
  - artifact SHA-256:
    `96dddcc8ff437c70518b1f720460506aa78910c02d6f7da695cce4fd2fdbf75b`
  - artifact upload ID: `6715726733`
  - repository attestation:
    `https://github.com/rodriguezaa22ar-boop/atlas-trust-infrastructure/attestations/25991842`
  - Rekor log:
    `https://search.sigstore.dev?logIndex=1404516311`

## Repo State

- Atlas is now SLSA-verifiable for GitHub-built release artifacts through the
  retained release workflow and GitHub Artifact Attestations.
- Atlas does not claim external SLSA certification.
- Verified SLSA attestation references are not yet recorded in Atlas release
  manifests.
- `atlas release slsa-verify` is not implemented yet.
- Earlier diagnostic smoke tags exposed and helped fix release-tag checkout,
  branch-context, annotated-tag, and tag-fetch behavior.
- No target-touching behavior was added.
- No production-ready, external audit, payment verification, legal compliance,
  or third-party assurance claim is made by this milestone.
