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

Verifier output includes:

```text
This receipt validates as a metadata-only proof record.
It does not prove external artifact availability, human intent, legal compliance, or artifact correctness.
```

## Examples

- [minimal.json](../examples/receipt/minimal.json): first receipt with
  `prev_hash: null`
- [software-action.json](../examples/receipt/software-action.json): metadata
  receipt for a software action
- [approval-workflow.json](../examples/receipt/approval-workflow.json):
  metadata receipt for an approval workflow
- [agent-action.json](../examples/receipt/agent-action.json): metadata receipt
  for an agent-adjacent action record

## Non-Goals

M131 does not add execution, scanning, CI/CD, ticketing, GRC automation, agent autonomy, or external artifact retrieval. It is only the smallest open-core receipt format and verifier for metadata-only proof records.
