# Atlas Receipt Replay v1

`atlas.receipt_replay.v1` is emitted by:

```bash
atlas receipt replay <receipt-file> [receipt-file ...] --json
```

The output is a deterministic, metadata-only replay summary for an ordered list
of receipt files. It verifies each `atlas.receipt.v1` record and checks local
ledger binding with `prev_hash -> event_hash` linkage.

## Required Fields

- `schema_version`: must be `atlas.receipt_replay.v1`.
- `status`: must be `ok`.
- `metadata_only`: must be `true`.
- `raw_artifacts_embedded`: must be `false`.
- `receipt_count`: number of receipts replayed.
- `first_event_hash`: canonical event hash for the first receipt.
- `chain_head_event_hash`: canonical event hash for the final receipt.
- `chain_head_receipt_hash`: canonical receipt hash for the final receipt.
- `ledger_binding`: linkage rule and status.
- `chain_checkpoint`: receipt count and final chain hashes.
- `chain`: ordered receipt metadata with path, receipt ID, action, hashes, and
  linkage status.
- `metadata_boundary`: explicit stored and excluded metadata classes.
- `known_limitations`: non-empty limitations for reviewer interpretation.

## Verification Rules

Replay succeeds only when:

- every receipt passes `atlas receipt verify`;
- the first receipt has `prev_hash: null`;
- every later receipt's `prev_hash` equals the previous receipt's
  `event_hash`;
- the emitted checkpoint reflects the final receipt in the provided order.

## Metadata Boundary

The replay summary may store receipt IDs, actions, file paths, SHA-256 hashes,
counts, linkage statuses, and known limitations.

It must not include raw artifacts, raw request or response bodies, secrets,
tokens, private keys, session contents, exploit payloads, or unredacted
evidence bodies.

Replay is read-only. It must not create runtime layout, append ledger events,
fetch artifacts, inspect external systems, or run tools.
