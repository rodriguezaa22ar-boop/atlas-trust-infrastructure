# AI Agent Event Receipt Profile

M146 defines an AI-agent event profile on top of the existing
`generic.external_event.v1` import-only adapter.

The profile treats an AI agent as an event source only:

```text
AI agent proposes or reports an action
-> Atlas imports the event
-> Atlas creates a metadata-only receipt
-> Atlas verifies and replays the proof chain
-> human and policy remain the authority
```

It does not turn Atlas into an AI execution engine.

## Boundary

The AI agent may propose or report metadata.

Atlas may:

- import a local `generic.external_event.v1` JSON event
- write the caller-requested receipt output
- verify the receipt
- replay linked AI-agent event receipts
- preserve the metadata-only proof envelope

Atlas must not:

- run tools for the AI agent
- approve the AI agent's proposal
- expand scope
- call a model provider
- call a network, webhook, browser, scanner, or backend
- embed raw prompts
- embed raw model responses
- embed system prompts
- embed tool output bodies
- embed API keys, credentials, browser/session data, raw logs, or private files

Core rule:

```text
AI agent may propose.
Atlas may verify the proof envelope.
Human and policy decide.
```

## Profile Fields

The profile uses the existing generic event fields rather than adding a second
adapter. AI-agent metadata is represented as inert refs.

| AI-agent concept | Generic event location |
| --- | --- |
| `agent_id` | `actor` |
| `agent_runtime` | `evidence_refs[]` as `ai_agent_profile://agent_runtime/...` |
| `model_label` | `evidence_refs[]` as `ai_agent_profile://model_label/...` |
| `task_id` | `subject.ref` |
| `operator_id` | `evidence_refs[]` as `ai_agent_profile://operator_id/...` |
| `proposed_action` | `event_type` and `evidence_refs[]` |
| `capability_id` | `evidence_refs[]` as `ai_agent_profile://capability_id/...` |
| `policy_decision` | `evidence_refs[]` as `ai_agent_profile://policy_decision/...` |
| `approval_required` | `evidence_refs[]` as `ai_agent_profile://approval_required/...` |
| `approval_refs` | `approval_refs[]` |
| `input_hash` | `evidence_refs[]` as `sha256:input:<hash>` |
| `output_hash` | `artifact_refs[]` or `evidence_refs[]` as a hash-only ref |
| `artifact_refs` | `artifact_refs[]` |
| `known_limitations` | `known_limitations[]` |

This keeps the profile compatible with `generic.external_event.v1` while still
making the reviewer-visible AI-agent context explicit.

## Example Commands

Import the proposal event:

```bash
./tools/atlas/bin/atlas receipt import-generic-event \
  examples/adapters/generic-external-event/ai-agent-action-event.json \
  --out /tmp/atlas-ai-agent-action-receipt.json
```

Verify it:

```bash
./tools/atlas/bin/atlas receipt verify \
  /tmp/atlas-ai-agent-action-receipt.json
```

Create a linked reported-result receipt:

```bash
prev_hash="$(jq -r '.event_hash' /tmp/atlas-ai-agent-action-receipt.json)"

./tools/atlas/bin/atlas receipt import-generic-event \
  examples/adapters/generic-external-event/ai-agent-result-event.json \
  --prev-hash "$prev_hash" \
  --out /tmp/atlas-ai-agent-result-receipt.json
```

Replay the linked AI-agent event chain:

```bash
./tools/atlas/bin/atlas receipt replay \
  /tmp/atlas-ai-agent-action-receipt.json \
  /tmp/atlas-ai-agent-result-receipt.json
```

Expected properties:

```text
receipt: ok
receipt replay: ok
metadata_only=true
raw_artifacts_embedded=false
known_limitations present
```

## Non-Guarantees

This profile does not prove:

- the agent was correct
- the agent was authorized to execute anything
- the model output was safe
- the source runtime was truthful
- the referenced artifacts exist
- human intent
- legal compliance
- production readiness
- external audit or certification

It proves only that Atlas can import, hash, verify, and replay a
metadata-only AI-agent event envelope under the generic adapter boundary.
