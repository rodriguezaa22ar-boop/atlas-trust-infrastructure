# `atlas.slsa_provenance.v1`

## Surface

```text
.github/workflows/release-slsa.yml
.github/workflows/release-slsa-generic.yml
GitHub Artifact Attestations
slsa-framework/slsa-github-generator
atlas release slsa-verify
docs/atlas/SLSA_PROVENANCE.md
```

## Purpose

`atlas.slsa_provenance.v1` documents the Atlas release-artifact provenance
contract for SLSA-verifiable builds. It is a readiness and verification
contract for retained metadata-only SLSA references, not an Atlas-emitted
packet.

The workflow builds a source release artifact from a Git commit, uploads the
artifact and checksum, and asks GitHub Artifact Attestations to generate a SLSA
build provenance attestation for the artifact.

Atlas also carries an official SLSA generic-generator workflow that sends
base64-encoded subject hashes to
`slsa-framework/slsa-github-generator/.github/workflows/generator_generic_slsa3.yml@v2.1.0`
for release tags.

## Required Fields For Retained References

When Atlas records SLSA provenance references, the record must include:

- `schema_version`: `atlas.slsa_provenance.v1`
- `metadata_only`: `true`
- `artifact.path`
- `artifact.sha256`
- `source.repository`
- `source.commit`
- `source.ref`
- `workflow.name`
- `workflow.path`
- `workflow.run_id`
- `workflow.run_url`
- `attestation.subject_digest`
- `attestation.verification_command`
- `attestation.verification_status`
- `known_limitations`
- `no_certification_overclaim`: `true`

## Required Workflow Properties

The release SLSA workflow should include:

- checkout with full history and tags
- release commit resolution with `${GITHUB_SHA}^{commit}` for annotated tag
  compatibility
- tag-triggered release builds must verify the tagged commit matches
  `origin/main`
- tag-triggered release builds must run QA from a local `main` branch tracking
  `origin/main`
- local Atlas QA with `nix-shell --run './bin/dev-qa'`
- strict v1 readiness with `atlas v1 status --strict`
- release artifact creation from `git archive` at `$ATLAS_RELEASE_COMMIT`
- SHA-256 checksum generation
- artifact upload
- `actions/attest@v4`
- `subject-path` pointing to the generated release artifact
- optional official generic-generator workflow:
  - `slsa-framework/slsa-github-generator/.github/workflows/generator_generic_slsa3.yml@v2.1.0`
  - `base64-subjects`
  - `upload-assets: true`
  - `.intoto.jsonl` provenance output
- permissions:
  - `contents: read`
  - `id-token: write`
  - `attestations: write`
  - `artifact-metadata: write`

## Verification Rules

Consumers should verify:

- the artifact SHA-256 matches the retained checksum
- the GitHub attestation verifies with `gh attestation verify`
- if official generic-generator provenance is published, `slsa-verifier
  verify-artifact` passes for the artifact and `.intoto.jsonl` provenance
- the attestation subject digest matches the artifact
- the repository owner and repository name are expected
- the workflow identity is expected
- the commit or tag matches the intended Atlas release
- `atlas release slsa-verify <reference> --commit <sha>` passes for the
  retained metadata-only reference
- `atlas release slsa-verify <reference> --artifact <artifact> --online` passes
  when the artifact and `gh` are available
- Atlas release packet and release artifact manifest verification still pass

## Metadata-Only Boundary

Allowed:

- artifact names and paths
- SHA-256 digests
- commit and ref identifiers
- workflow identity
- run IDs and URLs
- verification command and status
- known limitations

Forbidden:

- secrets
- tokens
- private keys
- raw runtime artifacts
- target secrets
- evidence bodies
- customer data
- private business records

## Non-Goals

- External SLSA certification
- Third-party audit
- Replacing Atlas release packets
- Replacing Atlas release artifact manifests
- Claiming production deployment readiness
- Storing private signing material
