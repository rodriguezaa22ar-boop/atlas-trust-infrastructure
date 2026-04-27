# `atlas.release_provenance.v1`

## Surface

```text
docs/retention/releases/*.provenance.json
```

## Purpose

Record metadata-only release provenance that binds a retained release trust
packet to a cryptographically signed Git tag.

This contract is consumed by `atlas production status`. It is not a raw build
attestation and does not embed runtime artifacts.

## Required Fields

- `schema_version`: must be `atlas.release_provenance.v1`.
- `metadata_only`: must be `true`.
- `commit`: release commit covered by the provenance packet.
- `signed_tag.name`: signed Git tag name.
- `signed_tag.target`: commit targeted by the signed tag.
- `signed_tag.verification`: must be `verified`.
- `signed_tag.signer_fingerprint`: signing key fingerprint observed when the
  packet was retained.
- `release_packet.path`: repository-relative path to the retained release
  trust packet.
- `release_packet.sha256`: SHA-256 hash of the retained release trust packet.
- `qa.status`: must be `pass`.
- `production_status.observed`: production status observed before retaining the
  provenance packet.
- `known_limitations`: non-empty list of retained limitations.
- `no_production_overclaim`: must be `true`.

## Verification Rules

`atlas production status` treats signing/provenance as ready only when:

- the latest `*.provenance.json` parses as JSON
- the schema, metadata-only flag, QA status, known limitations, and
  no-overclaim flag are present
- the provenance commit matches the current commit or the retained release
  commit immediately before the provenance-retention commit
- the referenced release packet exists under `docs/retention/releases/`
- the referenced release packet SHA-256 matches the retained hash
- `atlas release verify` succeeds for the referenced release packet and commit
- the signed tag exists as an annotated tag
- the signed tag resolves to the expected commit
- `git tag -v <tag>` verifies successfully with the available public key

## Metadata Boundary

Release provenance packets may include:

- commit IDs
- tag names
- signer fingerprints
- release packet paths
- SHA-256 hashes
- QA status
- production status observations
- known limitations

Release provenance packets must not include:

- raw runtime artifacts
- target secrets
- session contents
- packet captures
- credential material
- private keys
- tokens
- unredacted evidence bodies

## Non-Goals

- Replacing `atlas release verify`.
- Replacing signed tags.
- Claiming external audit.
- Claiming SLSA certification.
- Embedding private signing material.
