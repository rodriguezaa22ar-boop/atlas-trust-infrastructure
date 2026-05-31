# Try AI Agent Event Receipts

## Goal

Import synthetic AI-agent events into Atlas receipts, verify them, and replay a
two-receipt chain in under five minutes.

This path is for reviewers who want to test the M146 AI-agent event profile
without needing a model provider, network access, webhook, scanner, backend, or
agent runtime.

Atlas supports AI-agent action review by treating agents as metadata-only event
sources. The quickstart verifies proposed action and reported result receipts
without adding model execution, tool execution, approval authority, or raw
prompt/output storage.

## Requirements

Run from the repository root with the Nix development shell:

```bash
nix-shell
```

The shell provides `bash`, `jq`, and `sha256sum`, which are enough for the
generic event import, receipt verification, and replay path.

## Import A Proposed Action

Copy and paste:

```bash
./tools/atlas/bin/atlas receipt import-generic-event \
  examples/adapters/generic-external-event/ai-agent-action-event.json \
  --out /tmp/atlas-ai-agent-quickstart-1.json
```

Expected output:

```text
receipt: /tmp/atlas-ai-agent-quickstart-1.json
```

## Verify The Receipt

Copy and paste:

```bash
./tools/atlas/bin/atlas receipt verify \
  /tmp/atlas-ai-agent-quickstart-1.json
```

Expected output:

```text
receipt: ok
This receipt validates as a metadata-only proof record.
It does not prove external artifact availability, human intent, legal compliance, or artifact correctness.
```

## Import A Reported Result

Copy and paste:

```bash
prev_hash="$(jq -r '.event_hash' /tmp/atlas-ai-agent-quickstart-1.json)"

./tools/atlas/bin/atlas receipt import-generic-event \
  examples/adapters/generic-external-event/ai-agent-result-event.json \
  --prev-hash "$prev_hash" \
  --out /tmp/atlas-ai-agent-quickstart-2.json
```

Expected output:

```text
receipt: /tmp/atlas-ai-agent-quickstart-2.json
```

## Replay The Chain

Copy and paste:

```bash
./tools/atlas/bin/atlas receipt replay \
  /tmp/atlas-ai-agent-quickstart-1.json \
  /tmp/atlas-ai-agent-quickstart-2.json
```

Expected output:

```text
receipt replay: ok
receipts: 2
ledger binding: ok prev_hash -> event_hash
chain_head_event_hash: fbdbc3d57d09c5041274b7c037da3b64403e1fbe3795cda7daad4713e7fb51f0
chain_head_receipt_hash: d02dcbcdf2e22a156b0ff6d52f77bf658b07fc042391d4541e5bc4993f835018
metadata-only boundary: ok
This replay verifies receipt hashes and provided-order prev_hash linkage only.
It does not prove external artifact availability, human intent, legal compliance, artifact correctness, authorization, or production readiness.
```

## Replay As JSON

Copy and paste:

```bash
./tools/atlas/bin/atlas receipt replay \
  /tmp/atlas-ai-agent-quickstart-1.json \
  /tmp/atlas-ai-agent-quickstart-2.json \
  --json | jq .
```

Expected fields:

```text
schema_version: atlas.receipt_replay.v1
status: ok
metadata_only: true
raw_artifacts_embedded: false
receipt_count: 2
first_event_hash: 396b7440e4786a90758be59e28203b235c3514182fb797d905e41cbedd262f8b
chain_checkpoint.head_event_hash: fbdbc3d57d09c5041274b7c037da3b64403e1fbe3795cda7daad4713e7fb51f0
chain_checkpoint.head_receipt_hash: d02dcbcdf2e22a156b0ff6d52f77bf658b07fc042391d4541e5bc4993f835018
```

## Optional Local Model Helper Event

If a workstation has an optional builder-backed local model helper, record
important model-assisted actions with metadata only:

```bash
./tools/atlas/bin/atlas receipt import-generic-event \
  examples/adapters/generic-external-event/local-model-used-event.json \
  --out /tmp/atlas-local-model-used-receipt.json

./tools/atlas/bin/atlas receipt verify \
  /tmp/atlas-local-model-used-receipt.json
```

Expected output:

```text
receipt: /tmp/atlas-local-model-used-receipt.json
receipt: ok
```

The event type is:

```text
atlas_node.local_model.used
```

It records `timestamp`, `operator`, `model_label`, `task_label`,
`input_hash`, `output_hash`, `summary`, and `known_limitations`. It does not
store raw prompts or raw model output by default.

## What This Proves

- the input events match `generic.external_event.v1`
- the AI-agent profile uses the existing import-only adapter
- generated receipts preserve `metadata_only=true`
- generated receipts preserve `raw_artifacts_embedded=false`
- generated receipts include `known_limitations`
- generated receipts pass `atlas receipt verify`
- linked generated receipts pass `atlas receipt replay`
- the optional local model helper event can be represented as metadata only

The AI-agent profile is documented at
[adapters/AI_AGENT_EVENT_RECEIPT_PROFILE.md](adapters/AI_AGENT_EVENT_RECEIPT_PROFILE.md).
The generic adapter boundary is documented at
[adapters/GENERIC_EXTERNAL_EVENT_RECEIPT_ADAPTER.md](adapters/GENERIC_EXTERNAL_EVENT_RECEIPT_ADAPTER.md).
The event schema is documented at
[../schemas/generic-external-event.v1.schema.json](../schemas/generic-external-event.v1.schema.json).
The receipt canonicalization contract is documented at
[schemas/receipt-canonicalization.v1.md](schemas/receipt-canonicalization.v1.md).

## Known Limitations

- This is synthetic example data only.
- Atlas does not call a model provider, local model API, webhook, scanner,
  backend, or source system.
- Atlas does not execute actions, make approvals, or validate source-runtime
  truth.
- Atlas does not create ledgers, sessions, targets, reports, logs, releases,
  hidden state, or runtime directories.
- Atlas rejects raw prompt fields, raw model responses, system prompts, tool
  output bodies, embedded raw artifacts, private keys, tokens, and secret
  markers.
- The local model helper is optional workstation support only.
- Receipt replay verifies local receipt hashes and caller-provided chain order
  only.
- This quickstart does not prove model correctness, source-runtime truth,
  external artifact availability, human intent, legal compliance, artifact
  correctness, authorization, runtime correctness, production readiness,
  external audit status, or certification.
