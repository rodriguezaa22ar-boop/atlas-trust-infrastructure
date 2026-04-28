# `atlas.handoff_packet.v1`

## Surface

`atlas op handoff --json [operation] [packet-name]`

## Purpose

`atlas.handoff_packet.v1` is the machine-readable handoff packet contract for
an operation. It records operation identity, close readiness, freshness states,
artifact references, SHA-256 anchors, and known limitations without embedding
raw report bodies, evidence bodies, finding bodies, validation output, or ledger
contents.

## Required Fields

- `schema_version`: must be `atlas.handoff_packet.v1`.
- `generated_at`: packet generation timestamp.
- `operation`: operation name, id, status, target, and optional address.
- `metadata_only`: must be `true`.
- `raw_artifacts_embedded`: must be `false`.
- `readiness`: close readiness, next step, counts, freshness values, and latest
  material change labels.
- `artifacts`: latest report, evidence bundle, and evidence manifest references.
- `integrity`: operation ledger path, event count, SHA-256 anchor, and operation
  directory path.
- `metadata_boundary`: explicit stores and excludes lists.
- `known_limitations`: explicit non-guarantees and packet boundaries.

## Verification Rules

Handoff JSON packets are verified downstream by closeout manifests and archive
packets when they anchor the latest handoff path and SHA-256 hash. Consumers
must:

- parse the JSON object and schema version
- confirm `metadata_only` is `true`
- confirm `raw_artifacts_embedded` is `false`
- confirm the packet operation id matches the operation being reviewed
- reject forbidden raw-content markers before using the packet as retained proof
- verify artifact SHA-256 anchors where paths are recorded

## Metadata Boundary

Handoff JSON packets may include:

- local paths
- hashes
- counts
- timestamps
- freshness states
- readiness states
- known limitations

Handoff JSON packets must not include:

- raw report bodies
- raw evidence bodies
- finding bodies
- validation output
- raw ledger contents
- target secrets
- credentials
- private keys
- tokens
- packet captures
- session contents
- customer data
- sensitive business records

## Non-Goals

This packet is not external audit, legal compliance evidence, deployment
certification, cryptographic immutability, or proof that retained artifacts are
safe to disclose.
