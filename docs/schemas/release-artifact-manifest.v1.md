# `atlas.release_artifact_manifest.v1`

## Surface

```bash
atlas release manifest <manifest-name>
atlas release manifest-verify <manifest-name>
```

## Purpose

`atlas.release_artifact_manifest.v1` records the retained release artifacts that
make a local Atlas release independently reviewable: release packet, signed
provenance packet, retained signing public key, production dry-run note, signed
tag metadata, and optional milestone note.

The manifest is metadata-only. It stores paths, SHA-256 hashes, commit IDs, tag
IDs, SLSA attestation references, verification states, and known limitations.
It does not embed release packet bodies, raw runtime artifacts, target secrets,
session contents, packet captures, credential material, private keys, tokens,
or evidence bodies.

## Required Fields

- `schema_version`: must be `atlas.release_artifact_manifest.v1`
- `generated`: timestamp when the manifest was generated
- `manifest`: manifest name
- `metadata_only`: must be `true`
- `raw_artifacts_embedded`: must be `false`
- `release.commit`: full release commit hash
- `release.retained_by_commit`: commit that generated the manifest
- `repository.state_before_manifest`: records `clean` or `dirty`; clean is
  preferred, while dirty may occur when the manifest is assembled alongside
  uncommitted retained release evidence
- `repository.upstream_sync_before_manifest`: expected `synced`
- `signed_tag.name`
- `signed_tag.target`
- `signed_tag.tag_object`
- `signed_tag.verification`: expected `verified`
- `release_packet.path`
- `release_packet.sha256`
- `release_packet.verified`: expected `true`
- `provenance.path`
- `provenance.sha256`
- `provenance.verified`: expected `true`
- `production_dry_run.path`
- `production_dry_run.sha256`
- `production_dry_run.verified`: expected `true`
- `signing_public_key.path`
- `signing_public_key.sha256`
- `signing_public_key.verified`: expected `true`
- `slsa_provenance`: optional object for a verified
  `atlas.slsa_provenance.v1` reference
- `slsa_provenance.path`: retained SLSA reference JSON path when present
- `slsa_provenance.sha256`: retained SLSA reference JSON SHA-256 when present
- `slsa_provenance.schema_version`: expected `atlas.slsa_provenance.v1` when
  present
- `slsa_provenance.verified`: expected `true` when present
- `slsa_provenance.no_certification_overclaim`: expected `true` when present
- `artifacts[]`: kind/path/SHA-256/required records for retained files
- `contract.schema_document`: expected
  `docs/schemas/release-artifact-manifest.v1.md`
- `contract.guidance_document`: expected
  `docs/atlas/RELEASE_ARTIFACT_MANIFEST.md`
- `contract.slsa_schema_document`: expected
  `docs/schemas/slsa-provenance.v1.md`
- `contract.known_limitations_reference`: expected `known_limitations`
- `metadata_boundary.excludes`
- `known_limitations`
- `no_production_overclaim`: must be `true`

Required artifact classes:

- `release_packet`
- `release_provenance`
- `production_dry_run`
- `signing_public_key`

Optional artifact classes:

- `milestone_note`
- `slsa_provenance`

## Verification Rules

`atlas release manifest-verify` checks:

- schema version
- metadata-only and no-production-overclaim flags
- forbidden raw-content markers
- release commit match
- manifest generation commit availability
- signed tag metadata and target
- repository state and upstream-sync state recorded at manifest generation
- artifact count
- required artifact classes
- required artifact paths
- schema and guidance document references
- optional SLSA schema document reference
- known limitations reference
- SHA-256 hash for each listed artifact
- optional SLSA provenance reference validation
- release packet verification with `atlas release verify`
- provenance verification with retained public key and signed tag
- production dry-run note contract
- signed tag verification using the retained public key
- metadata boundary and known limitations

Verification fails if any required artifact is missing, stale, malformed, or no
longer verifies against the recorded release commit.

## Forbidden Content

The manifest must not include:

- raw runtime artifacts
- target secrets
- session contents
- packet captures
- credential material
- private keys
- tokens
- evidence bodies

## Non-Goals

- External audit attestation
- SLSA certification
- Deployment certification
- Enterprise production certification
- Immutable transparency log
