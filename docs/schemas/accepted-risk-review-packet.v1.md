# `atlas.accepted_risk_review_packet.v1`

## Surface

`atlas finding review-packet --json [packet-name] [--within days]`

The verifier consumes this packet with:

```bash
atlas finding review-verify [packet]
```

## Purpose

`atlas.accepted_risk_review_packet.v1` is the machine-readable accepted-risk
review packet contract for an operation. It records the review window,
accepted-risk queue counts, accepted-risk review states, and SHA-256 anchors
for the finding index and operation ledger without embedding raw evidence,
validation output, operator notes, or accepted-risk reason bodies.

## Required Fields

- `schema_version`: must be `atlas.accepted_risk_review_packet.v1`.
- `generated_at`: packet generation timestamp.
- `operation`: operation name, id, status, target, and optional address.
- `metadata_only`: must be `true`.
- `raw_artifacts_embedded`: must be `false`.
- `review_window`: today, review window in days, and due-by date.
- `queue_counts`: expired, due-soon, no-expiry, and current counts.
- `anchors`: finding index and operation ledger paths with SHA-256 anchors.
- `review_queue`: metadata-only accepted-risk rows.
- `metadata_boundary`: explicit stores and excludes lists.
- `known_limitations`: explicit non-guarantees and packet boundaries.

## Verification Rules

`atlas finding review-verify` must:

- parse the JSON object and schema version
- confirm `metadata_only` is `true`
- confirm `raw_artifacts_embedded` is `false`
- confirm the packet operation id matches the loaded operation
- reject forbidden raw-content markers
- verify the finding index SHA-256 anchor
- verify the operation ledger event count and SHA-256 anchor
- tolerate later accepted-risk review, audit, and archive packet ledger events
  when the recorded ledger prefix still matches

## Metadata Boundary

Accepted-risk review JSON packets may include:

- finding ids
- review states
- owner labels
- severity labels
- finding levels
- local paths
- hashes
- counts
- timestamps

Accepted-risk review JSON packets must not include:

- raw evidence bodies
- validation output
- operator notes
- accepted-risk reason bodies
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
certification, cryptographic immutability, or proof that accepted risks are
acceptable for any environment outside the recorded operation context.
