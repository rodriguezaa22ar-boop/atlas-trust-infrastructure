# Demo Receipt Packet

## Purpose

M138 binds the public demo path to a synthetic Atlas receipt chain and replay
path. It gives reviewers a local, deterministic way to inspect how demo-site
claims can be represented as `atlas.receipt.v1` records without making the
demo operational.

The receipt chain lives under:

```text
examples/receipt/demo-site/
```

It is synthetic only. It does not add a database, server, web UI, network
collector, agent execution, live Emergent integration, backend, persistence,
hidden state, or production deployability claim.

## Receipt Chain

Replay the chain from the repository root:

```bash
./tools/atlas/bin/atlas receipt replay \
  examples/receipt/demo-site/demo-site-boundary.json \
  examples/receipt/demo-site/demo-site-packet.json \
  examples/receipt/demo-site/demo-site-replay.json
```

For machine-readable reviewer output:

```bash
./tools/atlas/bin/atlas receipt replay \
  examples/receipt/demo-site/demo-site-boundary.json \
  examples/receipt/demo-site/demo-site-packet.json \
  examples/receipt/demo-site/demo-site-replay.json \
  --json
```

Expected receipt order:

| Index | Receipt | Meaning |
| --- | --- | --- |
| 1 | `demo-site-boundary.json` | records the synthetic demo-site boundary and binds to `docs/demo/DEMO_OPERATION.md` by SHA-256 |
| 2 | `demo-site-packet.json` | records the reviewer-safe demo receipt packet documentation |
| 3 | `demo-site-replay.json` | records the replay path and final checkpoint |

Each receipt must verify independently:

```bash
./tools/atlas/bin/atlas receipt verify examples/receipt/demo-site/demo-site-boundary.json
./tools/atlas/bin/atlas receipt verify examples/receipt/demo-site/demo-site-packet.json
./tools/atlas/bin/atlas receipt verify examples/receipt/demo-site/demo-site-replay.json
```

## Replay Output Shape

`atlas receipt replay --json` emits `atlas.receipt_replay.v1`.

The demo chain should report:

```json
{
  "schema_version": "atlas.receipt_replay.v1",
  "status": "ok",
  "metadata_only": true,
  "raw_artifacts_embedded": false,
  "receipt_count": 3,
  "ledger_binding": {
    "status": "ok",
    "rule": "receipt[n].prev_hash == receipt[n-1].event_hash"
  },
  "chain_checkpoint": {
    "receipt_count": 3,
    "head_event_hash": "bb79b7ba13bfc8b657a532c9a07cd3eb9c27020514c903e9cda4385f6e5012eb",
    "head_receipt_hash": "f0ba44315536c8397b4a42bc1a5b18bf3992b13752b83e465bed0850a1ea6c38"
  }
}
```

The canonicalization contract is documented at
[../schemas/receipt-canonicalization.v1.md](../schemas/receipt-canonicalization.v1.md).
Replay output is documented at
[../schemas/receipt-replay.v1.md](../schemas/receipt-replay.v1.md).

## Boundary

The demo receipt packet is metadata-only:

- `metadata_only=true`
- `raw_artifacts_embedded=false`
- `known_limitations` present on every receipt
- no raw artifacts
- no raw request or response bodies
- no credential material
- no packet captures
- no exploit payloads
- no execution
- no backend
- no persistence
- no hidden state

## Known Limitations

- The demo-site receipt chain is synthetic and local-only.
- The chain verifies receipt hashes and provided-order `prev_hash ->
  event_hash` linkage only.
- The chain does not prove external artifact availability, human intent, legal
  compliance, artifact correctness, authorization, runtime correctness,
  production readiness, or external audit status.
- The retained `docs/demo/DEMO_OPERATION.md` artifact hash is a review anchor,
  not a live deployment attestation.
