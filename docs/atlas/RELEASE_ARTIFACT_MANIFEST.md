# Release Artifact Manifest

## Purpose

The release artifact manifest is the metadata-only index for retained Atlas
release evidence. It binds the release packet, signed provenance packet,
retained signing public key, production dry-run note, signed tag metadata,
optional milestone note, and optional verified SLSA provenance reference into
one verifiable local release artifact set.

The manifest supports Atlas' trust-infrastructure direction: retained release
claims should be replayable, hash-bound, and inspectable without embedding
secrets or raw runtime content.

## Schema

The JSON schema version is:

```text
atlas.release_artifact_manifest.v1
```

The schema reference lives at:

```text
docs/schemas/release-artifact-manifest.v1.md
```

`atlas release manifest` writes the manifest under:

```text
docs/retention/releases/<name>.manifest.json
```

## Required Artifact Classes

Every manifest must include exactly one required artifact entry for each class:

- `release_packet`
- `release_provenance`
- `production_dry_run`
- `signing_public_key`

The optional artifact class is:

- `milestone_note`
- `slsa_provenance`

Each artifact entry must include:

- `kind`
- `path`
- `sha256`
- `required`

## Required Fields

Required manifest fields include:

- schema version
- generated timestamp
- manifest name
- metadata-only flags
- release commit
- manifest generation commit
- branch at manifest generation
- repository cleanliness and upstream sync state
- signed tag name, target, tag object, and verification state
- release packet path, SHA-256, and verification state
- provenance packet path, SHA-256, and verification state
- production dry-run note path, SHA-256, and verification state
- retained signing public key path, SHA-256, and verification state
- optional SLSA provenance reference path, SHA-256, verification state,
  artifact digest, workflow identity, attestation URL, and verification command
- artifact list
- schema document reference
- manifest guidance document reference
- known limitations reference
- metadata boundary
- known limitations
- no-production-overclaim flag

## Verification Rules

`atlas release manifest-verify` checks:

- schema version
- metadata-only and no-production-overclaim flags
- forbidden raw-content markers
- release commit match
- manifest generation commit availability
- signed tag metadata and target
- repository state and upstream sync state recorded at manifest generation
- artifact count
- required artifact classes
- required artifact paths
- schema and guidance document references
- known limitations reference
- retained artifact SHA-256 hashes
- optional SLSA provenance reference validation
- release packet verification
- signed provenance verification
- production dry-run note contract
- signed tag verification using the retained public key

Verification fails closed when required artifact entries, paths, hashes,
contract references, known limitations, signed tag metadata, or retained files
are missing or stale.

## Forbidden Contents

The manifest must not embed:

- raw runtime artifacts
- target secrets
- session contents
- packet captures
- credential material
- private keys
- tokens
- evidence bodies
- passwords
- API keys
- authorization headers
- cookies

The manifest may mention these classes only as excluded content in the metadata
boundary or known limitations.

## Relationship To SLSA Provenance

`atlas release manifest --slsa <reference>` records a retained
`atlas.slsa_provenance.v1` reference inside the release artifact manifest.

The SLSA block is optional. When present, `atlas release manifest-verify` checks
that the reference file exists, its SHA-256 matches the manifest, it uses the
expected schema, it reports `verification_status: verified`, its subject digest
matches the artifact SHA-256, its source commit matches the manifest release
commit, and the manifest contains a matching optional `slsa_provenance` artifact
entry.

This records verified GitHub/Sigstore provenance metadata. It does not make
Atlas externally SLSA-certified.

## Relationship To Release Packet

The release packet records the release commit, repository state, QA status, v1
readiness JSON, retained milestone references, and known limitations.

The release artifact manifest does not replace the release packet. It indexes
the retained release packet by path and SHA-256, then replays release packet
verification against the expected release commit.

## Relationship To Provenance

The signed provenance packet binds the release packet to a signed Git tag and a
retained public key.

The release artifact manifest indexes the provenance packet by path and
SHA-256, then verifies the provenance packet, retained public key, and signed
tag.

## Relationship To Production Status

`atlas production status` requires the latest release artifact manifest to
verify before reporting `production-ready` under the local Atlas production
contract.

This is not an external audit, SLSA certification, legal compliance claim, or
deployment certification.

## Relationship To Replay

Release replay verifies a release packet from the commit recorded inside that
packet. Manifest verification complements replay by checking that the retained
release packet, provenance packet, dry-run note, signing key, and signed tag
remain complete and hash-bound.

Together, release replay and manifest verification make the release trust chain
reviewable after later milestones advance the repository.

## Non-Guarantees

The release artifact manifest does not guarantee:

- external audit attestation
- immutable transparency logging
- enterprise certification
- deployment certification
- legal compliance
- cryptographic signing of each individual retained artifact
- protection against local repository tampering outside the local contract
