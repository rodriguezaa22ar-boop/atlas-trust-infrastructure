# Try Atlas Receipts

## Goal

Verify and replay a synthetic Atlas receipt chain in under five minutes.

This path is for reviewers who want to see the receipt boundary before reading
the full Atlas trust model. It uses committed, synthetic demo receipts only.

## Requirements

Run from the repository root with the Nix development shell:

```bash
nix-shell
```

The shell provides `bash`, `jq`, and `sha256sum`, which are enough for receipt
verification and replay.

## Verify One Receipt

Copy and paste:

```bash
./tools/atlas/bin/atlas receipt verify \
  examples/receipt/demo-site/demo-site-boundary.json
```

Expected output:

```text
receipt: ok
This receipt validates as a metadata-only proof record.
It does not prove external artifact availability, human intent, legal compliance, or artifact correctness.
```

## Replay The Demo Chain

Copy and paste:

```bash
./tools/atlas/bin/atlas receipt replay \
  examples/receipt/demo-site/demo-site-boundary.json \
  examples/receipt/demo-site/demo-site-packet.json \
  examples/receipt/demo-site/demo-site-replay.json
```

Expected output:

```text
receipt replay: ok
receipts: 3
ledger binding: ok prev_hash -> event_hash
chain_head_event_hash: bb79b7ba13bfc8b657a532c9a07cd3eb9c27020514c903e9cda4385f6e5012eb
chain_head_receipt_hash: f0ba44315536c8397b4a42bc1a5b18bf3992b13752b83e465bed0850a1ea6c38
metadata-only boundary: ok
This replay verifies receipt hashes and provided-order prev_hash linkage only.
It does not prove external artifact availability, human intent, legal compliance, artifact correctness, authorization, or production readiness.
```

## Replay As JSON

Copy and paste:

```bash
./tools/atlas/bin/atlas receipt replay \
  examples/receipt/demo-site/demo-site-boundary.json \
  examples/receipt/demo-site/demo-site-packet.json \
  examples/receipt/demo-site/demo-site-replay.json \
  --json | jq .
```

Expected fields:

```text
schema_version: atlas.receipt_replay.v1
status: ok
metadata_only: true
raw_artifacts_embedded: false
receipt_count: 3
ledger_binding.status: ok
chain_checkpoint.head_event_hash: bb79b7ba13bfc8b657a532c9a07cd3eb9c27020514c903e9cda4385f6e5012eb
chain_checkpoint.head_receipt_hash: f0ba44315536c8397b4a42bc1a5b18bf3992b13752b83e465bed0850a1ea6c38
```

## What This Proves

- the receipt files are valid `atlas.receipt.v1` records
- `metadata_only=true`
- `raw_artifacts_embedded=false`
- `known_limitations` are present
- stored receipt hashes match the local canonicalization contract
- the provided chain order satisfies `prev_hash -> event_hash`
- replay emits a deterministic `atlas.receipt_replay.v1` checkpoint

The canonicalization contract is documented at
[schemas/receipt-canonicalization.v1.md](schemas/receipt-canonicalization.v1.md).
The replay contract is documented at
[schemas/receipt-replay.v1.md](schemas/receipt-replay.v1.md).

## Known Limitations

- This is synthetic demo data only.
- Receipt replay verifies local receipt hashes and caller-provided chain order
  only.
- Receipt replay does not fetch artifacts, inspect external systems, run
  scanners, call a backend, or create hidden state.
- Receipt replay does not prove external artifact availability, human intent,
  legal compliance, artifact correctness, authorization, runtime correctness,
  production readiness, or external audit status.
