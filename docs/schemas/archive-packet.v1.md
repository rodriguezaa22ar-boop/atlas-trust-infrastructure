# `atlas.archive_packet.v1`

## Surface

`atlas op archive-packet --json [operation] [packet-name]`

The verifier consumes this packet with:

```bash
atlas op archive-verify [operation] [archive-packet]
```

## Purpose

`atlas.archive_packet.v1` is the machine-readable archive packet contract for
an operation closeout. It records archive status, readiness freshness,
verification state, retained artifact paths, hash anchors, and the operation
ledger anchor without embedding raw artifact contents.

## Required Fields

- `schema_version`: must be `atlas.archive_packet.v1`.
- `generated_at`: packet generation timestamp.
- `operation`: operation name, id, status, target, and optional address.
- `metadata_only`: must be `true`.
- `raw_artifacts_embedded`: must be `false`.
- `archive_status`: archive status and next step.
- `readiness`: close readiness counts and freshness values.
- `verification`: closeout, accepted-risk review packet, and audit packet
  verification states.
- `artifacts`: retained paths and SHA-256 anchors for the latest report,
  evidence manifest, handoff, closeout, accepted-risk review packet, audit
  packet, latest archive packet reference, operation ledger, and operation
  directory.
- `known_limitations`: explicit non-guarantees and packet boundaries.

## Verification Rules

`atlas op archive-verify` must:

- parse the JSON object and schema version
- confirm `metadata_only` is `true`
- confirm `raw_artifacts_embedded` is `false`
- confirm the packet operation id matches the loaded operation
- reject forbidden raw-content markers
- verify retained artifact SHA-256 anchors where paths are recorded
- verify the operation ledger event count and SHA-256 anchor
- report missing optional anchors as gaps rather than hard failures

## Metadata Boundary

Archive JSON packets may include:

- local paths
- hashes
- counts
- timestamps
- freshness states
- verification states
- known limitations

Archive JSON packets must not include:

- raw runtime artifacts
- unredacted evidence bodies
- target secrets
- credentials
- private keys
- tokens
- packet captures
- request or response bodies
- customer data
- sensitive business records

## Non-Goals

This packet is not external audit, legal compliance evidence, enterprise
certification, cryptographic immutability, or proof that retained artifact
contents are safe to disclose.
