# Atlas SLSA Provenance

## Purpose

Atlas release artifacts should be SLSA-verifiable before Atlas claims any SLSA
level. This document defines the current Atlas path for producing and checking
GitHub/Sigstore SLSA build provenance for a release artifact.

This is not external SLSA certification. It is a verifiable provenance
readiness contract for Atlas release artifacts.

## Current Workflow

The release artifact workflow lives at:

```text
.github/workflows/release-slsa.yml
```

It runs on:

- manual `workflow_dispatch`
- release-style tags matching `atlas-v*`
- release-style tags matching `atlas-release-*`

Before building an artifact, the workflow runs:

```bash
git diff --check
nix-shell --run './bin/dev-qa'
nix-shell --run './tools/atlas/bin/atlas v1 status --strict'
```

The workflow resolves `${GITHUB_SHA}^{commit}` into `ATLAS_RELEASE_COMMIT` so
annotated tags and commit refs both build from the underlying Git commit. For
tag-triggered releases, that resolved tagged commit must match `origin/main`.
The workflow then checks out a local `main` branch at that exact commit and
sets `origin/main` as its upstream before running Atlas QA. This preserves the
exact release commit while keeping Atlas release and production gates in the
same branch/tracking context they verify locally.

It then builds a source release artifact from the exact Git commit:

```bash
git archive --format=tar --prefix="<artifact>/" "$ATLAS_RELEASE_COMMIT" | gzip -n
```

The artifact is uploaded with:

- the `.tar.gz` release artifact
- a `.sha256` checksum file
- a metadata env file containing commit, ref, workflow, run ID, artifact path,
  and SHA-256

Finally, the workflow uses GitHub Artifact Attestations through:

```yaml
uses: actions/attest@v4
with:
  subject-path: ${{ env.artifact }}
```

By default, `actions/attest` generates a SLSA build provenance attestation for
the subject artifact.

## Required Workflow Permissions

The workflow requires:

```yaml
permissions:
  contents: read
  id-token: write
  attestations: write
  artifact-metadata: write
```

`id-token: write` lets the workflow request a short-lived signing identity.
`attestations: write` stores the attestation. `artifact-metadata: write`
supports GitHub's artifact metadata record.

## Verification

After a workflow run produces an artifact, a consumer should verify:

```bash
gh attestation verify <artifact>.tar.gz \
  --repo rodriguezaa22ar-boop/atlas-trust-infrastructure
```

The verification should establish:

- the attestation signature verifies
- the subject digest matches the downloaded artifact
- the source repository is `rodriguezaa22ar-boop/atlas-trust-infrastructure`
- the workflow identity is expected
- the commit/ref matches the intended release

For policy-grade verification, record the expected subject SHA-256, source
repository, builder/workflow identity, tag or commit, and run URL in the
release notes or retained Atlas release manifest.

## Retained Smoke Verification

Milestone 98 records a successful tag-triggered SLSA smoke run:

- Tag: `atlas-release-m101-slsa-smoke`
- Commit: `087579936838faf7a5c8e3a242fd27f90ded88d5`
- Workflow run:
  `https://github.com/rodriguezaa22ar-boop/atlas-trust-infrastructure/actions/runs/25128727308`
- Artifact:
  `atlas-trust-infrastructure-atlas-release-m101-slsa-smoke-087579936838.tar.gz`
- Artifact SHA-256:
  `96dddcc8ff437c70518b1f720460506aa78910c02d6f7da695cce4fd2fdbf75b`
- Repository attestation:
  `https://github.com/rodriguezaa22ar-boop/atlas-trust-infrastructure/attestations/25991842`
- Rekor log:
  `https://search.sigstore.dev?logIndex=1404516311`

This proves the current workflow can build, upload, and attest a release-style
artifact. It does not mean external SLSA certification. Atlas release manifests
can now record verified SLSA attestation references with
`atlas release manifest --slsa <reference>`.

## Relationship To Atlas Release Trust

Atlas already has local release trust artifacts:

- release packet
- signed release provenance packet
- retained public key
- release artifact manifest
- production dry-run note
- milestone retention note

SLSA provenance adds an external build-provenance layer for the actual release
artifact generated in GitHub Actions.

The intended chain is:

```text
Git tag / workflow dispatch
-> GitHub Actions build
-> source release artifact
-> SLSA provenance attestation
-> gh attestation verify
-> Atlas release packet
-> Atlas release artifact manifest
-> Atlas production status
```

## Metadata Boundary

SLSA provenance references retained by Atlas should stay metadata-only.

The workflow and Atlas SLSA docs may retain:

- artifact name
- artifact SHA-256
- commit
- ref
- workflow name
- run ID or run URL
- attestation URL or verification command
- expected repository owner and repository name
- known limitations

They must not retain:

- secrets
- tokens
- private keys
- raw customer data
- raw operation evidence bodies
- packet captures
- credentials
- private business records

## Non-Guarantees

This readiness layer does not mean:

- external SLSA certification
- third-party audit
- enterprise deployment certification
- tamper-proof local state
- legal compliance
- production deployment approval

It means Atlas has a workflow and verification contract for producing a
GitHub/Sigstore-backed SLSA provenance attestation for release artifacts.

## Next Hardening

- Add an `atlas release slsa-verify` wrapper for `gh attestation verify`.
- Add policy checks for expected workflow identity, tag, commit, and artifact
  digest.
- Publish SLSA verification commands with each release.
