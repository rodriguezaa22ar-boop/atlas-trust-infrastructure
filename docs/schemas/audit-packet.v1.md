# `atlas.audit_packet.v1`

## Surface

`atlas op audit-packet --json [operation] [packet-name]`

The verifier consumes this packet with:

```bash
atlas op audit-verify [operation] [audit-packet]
```

## Purpose

`atlas.audit_packet.v1` is the machine-readable audit packet contract for an
operation. It records operation identity, ledger anchors, event counts,
freshness states, closeout verification state, closeout manifest hash anchors,
and known limitations without embedding raw timeline details or raw artifacts.

## Required Fields

- `schema_version`: must be `atlas.audit_packet.v1`.
- `generated_at`: packet generation timestamp.
- `operation`: operation name, id, status, and target.
- `metadata_only`: must be `true`.
- `raw_artifacts_embedded`: must be `false`.
- `ledger`: operation ledger path, event count, and SHA-256 anchor.
- `closeout_verification`: closeout verification status, optional manifest
  path, optional manifest SHA-256 anchor, and problem count.
- `readiness`: accepted-risk count, accepted-risk review packet reference, and
  freshness values for report, bundle, handoff, closeout, audit packet, and
  archive packet.
- `event_counts`: grouped ledger event counts.
- `metadata_boundary`: explicit stores and excludes lists.
- `known_limitations`: non-guarantees and verification boundaries.

## Verification Rules

`atlas op audit-verify` must:

- parse the JSON object and schema version
- confirm `metadata_only` is `true`
- confirm `raw_artifacts_embedded` is `false`
- confirm the packet operation id matches the loaded operation
- reject forbidden raw-content markers
- verify the operation ledger event count and SHA-256 anchor
- tolerate later archive-packet ledger events when the recorded ledger prefix
  still matches
- verify the recorded closeout manifest SHA-256 anchor when a manifest is
  recorded

## Metadata Boundary

Audit JSON packets may include:

- operation labels
- ledger paths
- event counts
- hashes
- freshness states
- verification states
- known limitations

Audit JSON packets must not include:

- raw runtime artifacts
- raw timeline details
- target secrets
- credentials
- private keys
- tokens
- packet captures
- session contents
- unredacted evidence bodies
- exploit payloads

## Non-Goals

This packet is not external audit, legal compliance evidence, deployment
certification, cryptographic immutability, or proof that retained artifacts are
safe to disclose.
