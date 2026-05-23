# Generic External Event Receipt Adapter

M143 adds the first executable import-only receipt adapter:

```text
generic.external_event.v1
```

The adapter reads one local JSON event file and normalizes it into one
`atlas.receipt.v1` receipt. It is intentionally narrow:

```text
input event JSON -> normalized metadata -> Atlas receipt -> verify -> replay
```

## Boundary

This adapter is local-file import only.

It may:

- read a caller-provided `generic.external_event.v1` JSON file
- write the caller-requested receipt output file
- map event metadata into `atlas.receipt.v1`
- preserve `metadata_only=true`
- preserve `raw_artifacts_embedded=false`
- require `known_limitations`

It must not:

- call the network
- query GitHub, scanners, ticketing systems, cloud APIs, or webhooks
- execute external actions
- create runtime state, hidden cache files, ledgers, sessions, logs, or targets
- embed raw request or response bodies
- embed raw artifacts, packet captures, credentials, tokens, or private keys
- claim external audit, certification, legal compliance, or production approval

## Event Shape

The input event contract is documented at:

```text
schemas/generic-external-event.v1.schema.json
```

Required safety fields:

```text
metadata_only=true
raw_artifacts_embedded=false
known_limitations=[...]
```

The adapter maps:

| Event field | Receipt field |
| --- | --- |
| `event_id` | deterministic `receipt_id` suffix |
| `observed_at` | `timestamp` |
| `event_type` | `action` |
| `actor` | `actor` |
| `subject.type` / `subject.ref` | `subject` |
| `source_ref` + `evidence_refs` | `evidence_refs` |
| `artifact_refs` | `artifact_refs` |
| `approval_refs` | `approval_refs` |
| `known_limitations` | `known_limitations` plus adapter non-guarantee |

## Commands

Create a receipt from the minimal synthetic event:

```bash
./tools/atlas/bin/atlas receipt import-generic-event \
  examples/adapters/generic-external-event/minimal-event.json \
  --out /tmp/atlas-generic-event-receipt-1.json
```

Verify it:

```bash
./tools/atlas/bin/atlas receipt verify /tmp/atlas-generic-event-receipt-1.json
```

Create a linked second receipt:

```bash
prev_hash="$(jq -r '.event_hash' /tmp/atlas-generic-event-receipt-1.json)"

./tools/atlas/bin/atlas receipt import-generic-event \
  examples/adapters/generic-external-event/approval-event.json \
  --prev-hash "$prev_hash" \
  --out /tmp/atlas-generic-event-receipt-2.json
```

Replay the chain:

```bash
./tools/atlas/bin/atlas receipt replay \
  /tmp/atlas-generic-event-receipt-1.json \
  /tmp/atlas-generic-event-receipt-2.json
```

Expected result:

```text
receipt replay: ok
ledger binding: ok prev_hash -> event_hash
metadata-only boundary: ok
```

## Non-Guarantees

The adapter proves only that Atlas can validate and hash the imported metadata
shape into a receipt.

It does not prove:

- source-system truth
- source-system availability
- human intent
- legal compliance
- artifact correctness
- authorization
- production readiness
- external audit or certification

The generated receipt remains reviewer-safe because it is metadata-only and
passes the normal Atlas receipt verifier.

## Profiles

- [AI Agent Event Receipt Profile](AI_AGENT_EVENT_RECEIPT_PROFILE.md):
  metadata-only AI-agent proposal/report events imported through the existing
  generic adapter. The agent is an event source only, not an authority or
  execution engine.
