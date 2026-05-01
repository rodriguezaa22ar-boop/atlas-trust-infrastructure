# Atlas SLSA Provenance

## Purpose

Atlas release artifacts should be SLSA-verifiable before Atlas claims any SLSA
level. This document defines the current Atlas path for producing and checking
GitHub/Sigstore SLSA build provenance for a release artifact.

This is not external SLSA certification. It is a verifiable provenance
readiness contract for Atlas release artifacts.

M117 moves this surface from explanation toward an implementation-forward
candidate: Atlas can build a public metadata-only release artifact in GitHub
Actions, bind it to a SHA-256 digest, request GitHub-hosted provenance or
attestation, and retain the expected source/workflow/issuer metadata for
review.

## Current Workflow

The release artifact workflow lives at:

```text
.github/workflows/release-slsa.yml
```

A parallel official generic-generator workflow lives at:

```text
.github/workflows/release-slsa-generic.yml
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
- a `.contents.txt` contents manifest generated from the tarball
- a metadata env file containing commit, ref, workflow, run ID, artifact path,
  contents manifest path, metadata boundary, and SHA-256

Before upload, the workflow checks the artifact contents manifest for root
runtime-state directories and forbidden sensitive path markers. This is a
path-level guardrail, not DLP and not an inspection of raw business contents.

Finally, the workflow uses GitHub Artifact Attestations through:

```yaml
# actions/attest v4 pinned to immutable commit.
uses: actions/attest@59d89421af93a897026c735860bf21b6eb4f7b26
with:
  subject-path: ${{ env.artifact }}
```

By default, `actions/attest` generates a SLSA build provenance attestation for
the subject artifact. The workflow also pins `actions/checkout`,
`cachix/install-nix-action`, and `actions/upload-artifact` to immutable commit
SHAs while preserving comments with the upstream version labels.

The `Official SLSA Generic Provenance` workflow follows the same QA,
readiness, tag, and artifact rules, then passes the artifact subject hash to:

```yaml
# slsa-framework/slsa-github-generator v2.1.0 pinned to immutable commit.
uses: slsa-framework/slsa-github-generator/.github/workflows/generator_generic_slsa3.yml@f7dd8c54c2067bafc12ca7a55595d5ee9b75204a
with:
  base64-subjects: "${{ needs.build.outputs.hashes }}"
  upload-assets: true
```

That workflow is intended for release tags and publishes an `.intoto.jsonl`
provenance file beside the release artifact. The publish path also pins
`actions/download-artifact` and `softprops/action-gh-release` to immutable
commit SHAs.

## Required Workflow Permissions

The workflow requires:

```yaml
permissions:
  contents: read
  id-token: write
  attestations: write
```

`id-token: write` lets the workflow request a short-lived signing identity.
`attestations: write` stores the attestation.

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
- the issuer identity is GitHub Actions OIDC/Sigstore attestation identity
- the commit/ref matches the intended release

For policy-grade verification, record the expected subject SHA-256, source
repository, builder/workflow identity, issuer identity, tag or commit, and run
URL in the release notes or retained Atlas release manifest.

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

Retained SLSA references can be checked locally with:

```bash
atlas release slsa-verify <reference>.slsa.json --commit <sha>
```

## Retained Release Candidate

Release candidate `atlas-v0.4.0-rc1` records the first retained
release-candidate SLSA reference:

```text
docs/retention/releases/atlas-v0.4.0-rc1.slsa.json
```

Evidence:

- Commit: `59667bf875871c1e27dbd72de20c983ac262b43b`
- Artifact:
  `atlas-trust-infrastructure-atlas-v0.4.0-rc1-59667bf87587.tar.gz`
- Artifact SHA-256:
  `a6fad42ced88648e49b8cbb9fcfe90533e2e389145277482f1000449108d0805`
- GitHub Artifact Attestation:
  `https://github.com/rodriguezaa22ar-boop/atlas-trust-infrastructure/attestations/26040322`
- GitHub attestation workflow:
  `https://github.com/rodriguezaa22ar-boop/atlas-trust-infrastructure/actions/runs/25153272091`
- Official generic-generator workflow:
  `https://github.com/rodriguezaa22ar-boop/atlas-trust-infrastructure/actions/runs/25153272179`
- Official generic-generator provenance SHA-256:
  `54e0f5f070192c2716d6923868fd43b2eeab64e588caad6ec11342fdb3d046e5`

`slsa-verifier verify-artifact` passed for the downloaded release artifact and
`.intoto.jsonl` provenance. After GitHub CLI authentication, Atlas also ran
`atlas release slsa-verify --artifact --online` successfully, which executed
`gh attestation verify` through the Atlas verifier.

This command verifies the metadata-only reference contract, recorded
`gh attestation verify` status, source commit, artifact digest, workflow path,
issuer identity, GitHub run URL, known limitations, and
no-certification-overclaim flag. It does not download artifacts.

When a release artifact has been downloaded, the local artifact hash can also be
checked:

```bash
atlas release slsa-verify <reference>.slsa.json \
  --commit <sha> \
  --artifact <artifact>.tar.gz
```

When the GitHub CLI is installed and the artifact is available locally, Atlas
can also run online attestation verification:

```bash
atlas release slsa-verify <reference>.slsa.json --artifact <artifact>.tar.gz --online
```

The direct GitHub command remains:

```bash
gh attestation verify <artifact>.tar.gz \
  --repo rodriguezaa22ar-boop/atlas-trust-infrastructure
```

For official generic-generator provenance, verify the downloaded `.intoto.jsonl`
file with `slsa-verifier`:

```bash
slsa-verifier verify-artifact <artifact>.tar.gz \
  --provenance-path <artifact>.intoto.jsonl \
  --source-uri github.com/rodriguezaa22ar-boop/atlas-trust-infrastructure \
  --source-tag <tag>
```

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

The claim boundary is retained in:

```text
docs/atlas/SLSA_CLAIM.md
docs/atlas/INDEPENDENT_REVIEW_READINESS.md
docs/retention/releases/atlas-m101-slsa-claim-evidence.md
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

- Publish a real release candidate tag and retain its downloaded artifact,
  attestation, SLSA reference, release packet, and release artifact manifest.
- Run `atlas release slsa-verify --artifact --online` against that release
  candidate.
- Run `slsa-verifier verify-artifact` for the official generic-generator
  `.intoto.jsonl` file.
- Send the retained reviewer packet to an independent reviewer.
