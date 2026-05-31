# Try The Generic Event Adapter

## Goal

Import a synthetic external event into an Atlas receipt, verify it, and replay a
two-receipt chain in under five minutes.

This path is for reviewers who want to test the first import-only adapter
without needing a source system, network access, scanner, webhook, or backend.

Atlas supports external-event review by turning local metadata files into
replayable receipts. This gives reviewers an import, verify, and replay path
without expanding Atlas into a collector or source-system authority.

## Requirements

Run from the repository root with the Nix development shell:

```bash
nix-shell
```

The shell provides `bash`, `jq`, and `sha256sum`, which are enough for the
adapter import, receipt verification, and replay path.

## Import One Event

Copy and paste:

```bash
./tools/atlas/bin/atlas receipt import-generic-event \
  examples/adapters/generic-external-event/minimal-event.json \
  --out /tmp/atlas-generic-event-quickstart-1.json
```

Expected output:

```text
receipt: /tmp/atlas-generic-event-quickstart-1.json
```

## Verify The Receipt

Copy and paste:

```bash
./tools/atlas/bin/atlas receipt verify \
  /tmp/atlas-generic-event-quickstart-1.json
```

Expected output:

```text
receipt: ok
This receipt validates as a metadata-only proof record.
It does not prove external artifact availability, human intent, legal compliance, or artifact correctness.
```

## Import A Linked Event

Copy and paste:

```bash
prev_hash="$(jq -r '.event_hash' /tmp/atlas-generic-event-quickstart-1.json)"

./tools/atlas/bin/atlas receipt import-generic-event \
  examples/adapters/generic-external-event/approval-event.json \
  --prev-hash "$prev_hash" \
  --out /tmp/atlas-generic-event-quickstart-2.json
```

Expected output:

```text
receipt: /tmp/atlas-generic-event-quickstart-2.json
```

## Replay The Chain

Copy and paste:

```bash
./tools/atlas/bin/atlas receipt replay \
  /tmp/atlas-generic-event-quickstart-1.json \
  /tmp/atlas-generic-event-quickstart-2.json
```

Expected output:

```text
receipt replay: ok
receipts: 2
ledger binding: ok prev_hash -> event_hash
chain_head_event_hash: 005591822b5807e694a1d983b9e97288bb2821bb324c9bd65a58993d4e92efea
chain_head_receipt_hash: 0bb047acaf335aceeef986ef655c5194a5024af6036b6d7899887e458129a945
metadata-only boundary: ok
This replay verifies receipt hashes and provided-order prev_hash linkage only.
It does not prove external artifact availability, human intent, legal compliance, artifact correctness, authorization, or production readiness.
```

## Replay As JSON

Copy and paste:

```bash
./tools/atlas/bin/atlas receipt replay \
  /tmp/atlas-generic-event-quickstart-1.json \
  /tmp/atlas-generic-event-quickstart-2.json \
  --json | jq .
```

Expected fields:

```text
schema_version: atlas.receipt_replay.v1
status: ok
metadata_only: true
raw_artifacts_embedded: false
receipt_count: 2
first_event_hash: 78f12641e7b0cd4a9e34d3be6d66f2ed490965ad455e6116d6bad222b7288991
chain_checkpoint.head_event_hash: 005591822b5807e694a1d983b9e97288bb2821bb324c9bd65a58993d4e92efea
chain_checkpoint.head_receipt_hash: 0bb047acaf335aceeef986ef655c5194a5024af6036b6d7899887e458129a945
```

## What This Proves

- the input events match `generic.external_event.v1`
- the adapter reads local event JSON only
- the adapter writes only the requested output receipt files
- generated receipts preserve `metadata_only=true`
- generated receipts preserve `raw_artifacts_embedded=false`
- generated receipts include `known_limitations`
- generated receipts pass `atlas receipt verify`
- linked generated receipts pass `atlas receipt replay`

The adapter boundary is documented at
[adapters/GENERIC_EXTERNAL_EVENT_RECEIPT_ADAPTER.md](adapters/GENERIC_EXTERNAL_EVENT_RECEIPT_ADAPTER.md).
The event schema is documented at
[../schemas/generic-external-event.v1.schema.json](../schemas/generic-external-event.v1.schema.json).
The receipt canonicalization contract is documented at
[schemas/receipt-canonicalization.v1.md](schemas/receipt-canonicalization.v1.md).

## Known Limitations

- This is synthetic example data only.
- The adapter does not call a network, webhook, API, scanner, backend, or
  source system.
- The adapter does not execute actions, make approvals, or validate source
  system truth.
- The adapter does not create ledgers, sessions, targets, reports, logs,
  releases, hidden state, or runtime directories.
- The adapter rejects raw request bodies, raw response bodies, embedded raw
  artifacts, private keys, tokens, and secret markers.
- Receipt replay verifies local receipt hashes and caller-provided chain order
  only.
- This quickstart does not prove external artifact availability, human intent,
  legal compliance, artifact correctness, authorization, runtime correctness,
  production readiness, external audit status, or certification.
