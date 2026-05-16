# Atlas Receipt v1

Atlas Receipt v1 creates and verifies portable, metadata-only proof receipts for critical digital actions.

Receipts are public trust records. They record who or what produced an action
claim, what the claim refers to, which metadata evidence or approval references
support it, and how the receipt hash-links to the previous receipt when a chain
exists.

## Boundary

Receipts are metadata-only. They may include IDs, labels, timestamps, reference
paths, SHA-256 hashes, approval references, evidence references, and known
limitations.

Receipts must not include raw artifacts, raw request or response bodies,
secrets, credentials, tokens, private keys, session contents, exploit payloads,
or unredacted evidence bodies.

Receipt verification proves only that:

- the receipt is valid JSON with schema `atlas.receipt.v1`
- `metadata_only` is `true`
- `raw_artifacts_embedded` is `false`
- required metadata fields are present
- forbidden raw-content fields or sensitive markers are absent
- `event_hash` matches canonical receipt content without `event_hash` or
  `receipt_hash`
- `receipt_hash` matches canonical receipt content without `receipt_hash`
- `prev_hash` is either `null` for the first receipt or a SHA-256 event hash

Receipt verification does not prove external artifact availability, human
intent, legal compliance, artifact correctness, authorization, or production
readiness.

## Commands

Create a receipt:

```bash
./tools/atlas/bin/atlas receipt create \
  --action software.release.packet.created \
  --actor atlas-release-operator \
  --subject-type git-commit \
  --subject HEAD \
  --evidence-ref docs/retention/releases/atlas-current.json \
  --artifact-ref docs/retention/releases/atlas-current.json=<sha256> \
  --out receipt.json
```

Verify a receipt:

```bash
./tools/atlas/bin/atlas receipt verify receipt.json
```

Replay a linked receipt chain:

```bash
./tools/atlas/bin/atlas receipt replay \
  examples/receipt/minimal.json \
  examples/receipt/software-action.json \
  examples/receipt/approval-workflow.json \
  examples/receipt/agent-action.json
```

Verifier output includes:

```text
This receipt validates as a metadata-only proof record.
It does not prove external artifact availability, human intent, legal compliance, or artifact correctness.
```

Replay output includes a deterministic metadata-only checkpoint:

```text
receipt replay: ok
ledger binding: ok prev_hash -> event_hash
metadata-only boundary: ok
```

`atlas receipt replay` verifies every receipt, then validates the caller-provided
sequence by requiring:

- the first receipt to have `prev_hash: null`
- every later receipt's `prev_hash` to equal the previous receipt's
  `event_hash`
- the final chain checkpoint to be the last receipt's `event_hash` and
  `receipt_hash`

Replay is read-only. It does not create runtime directories, append to operation
ledgers, run tools, fetch artifacts, or inspect external systems.

## Ledger Binding

A receipt chain is an append-only file-backed ledger when reviewers preserve the
receipt files in order and retain the replay checkpoint:

- append by adding a new receipt whose `prev_hash` equals the previous
  receipt's `event_hash`
- checkpoint by recording the replay `receipt_count`,
  `chain_head_event_hash`, and `chain_head_receipt_hash`
- verify by replaying the same ordered receipt list with `atlas receipt replay`

This binding is local and metadata-only. It proves canonical receipt hashes and
provided-order linkage, not artifact availability or production readiness.

## Examples

- [minimal.json](../examples/receipt/minimal.json): first receipt with
  `prev_hash: null`
- [software-action.json](../examples/receipt/software-action.json): metadata
  receipt for a software action
- [approval-workflow.json](../examples/receipt/approval-workflow.json):
  metadata receipt for an approval workflow
- [agent-action.json](../examples/receipt/agent-action.json): metadata receipt
  for an agent-adjacent action record
- [linked-chain/README.md](../examples/receipt/linked-chain/README.md):
  reviewer replay example for the four linked receipt files

## Non-Goals

M131 does not add execution, scanning, CI/CD, ticketing, GRC automation, agent autonomy, or external artifact retrieval. It is only the smallest open-core receipt format and verifier for metadata-only proof records.

M133 adds local receipt replay and ledger binding only. It does not add a
database, server, web UI, agent execution, network collector, automation runner,
or hidden receipt state.
