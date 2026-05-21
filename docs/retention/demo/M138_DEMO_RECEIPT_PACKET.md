# M138 Demo Receipt Packet

## Purpose

This retained demo note records the synthetic receipt packet used to bind the
public demo path to Atlas Receipt v1 verification and replay.

## Chain

```text
examples/receipt/demo-site/demo-site-boundary.json
examples/receipt/demo-site/demo-site-packet.json
examples/receipt/demo-site/demo-site-replay.json
```

## Reviewer Commands

```bash
./tools/atlas/bin/atlas receipt verify examples/receipt/demo-site/demo-site-boundary.json
./tools/atlas/bin/atlas receipt verify examples/receipt/demo-site/demo-site-packet.json
./tools/atlas/bin/atlas receipt verify examples/receipt/demo-site/demo-site-replay.json

./tools/atlas/bin/atlas receipt replay \
  examples/receipt/demo-site/demo-site-boundary.json \
  examples/receipt/demo-site/demo-site-packet.json \
  examples/receipt/demo-site/demo-site-replay.json \
  --json
```

## Checkpoint

```text
schema_version: atlas.receipt_replay.v1
receipt_count: 3
chain_head_event_hash: bb79b7ba13bfc8b657a532c9a07cd3eb9c27020514c903e9cda4385f6e5012eb
chain_head_receipt_hash: f0ba44315536c8397b4a42bc1a5b18bf3992b13752b83e465bed0850a1ea6c38
metadata_only: true
raw_artifacts_embedded: false
```

## Boundary

This is a docs/examples retention record only. It does not add a database,
server, web UI, network collector, agent execution, live Emergent integration,
backend, persistence, hidden state, or production deployability claim.

The chain is synthetic and metadata-only. It does not prove external artifact
availability, human intent, legal compliance, artifact correctness,
authorization, runtime correctness, production readiness, or external audit
status.
