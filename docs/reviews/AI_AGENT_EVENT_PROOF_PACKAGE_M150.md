# AI-Agent Event Proof Package M150

## Purpose

This proof package gives reviewers one place to inspect the AI-agent event
receipt path introduced across M146 through M149.

It packages the existing public proof surface only:

- M146 AI-agent event receipt profile.
- M147 AI-agent event quickstart.
- M148 AI-agent event security regression.
- M149 AI-agent event public reviewer dry-run.

This package does not add agent execution, runtime behavior, receipt
semantics, a network collector, a database, a server, a web UI, or a second
adapter. It uses only the existing `generic.external_event.v1` adapter and the
existing receipt verify and replay commands.

Boundary statement:

```text
AI agents are event sources only.
Atlas is verifier only.
Human and policy remain authority.
```

## Reviewed Commit

```text
81d4c3c329f805108ceb8eed70c97bbfc47146d8
```

This is the merged M149 checkpoint on `main`. It includes the AI-agent event
profile, quickstart, security regression, public reviewer dry-run, examples,
and retained milestone notes that this package references.

## Package Map

Primary reviewer entry points:

- [docs/TRY_AI_AGENT_EVENT_RECEIPTS.md](../TRY_AI_AGENT_EVENT_RECEIPTS.md)
- [docs/adapters/AI_AGENT_EVENT_RECEIPT_PROFILE.md](../adapters/AI_AGENT_EVENT_RECEIPT_PROFILE.md)
- [docs/adapters/GENERIC_EXTERNAL_EVENT_RECEIPT_ADAPTER.md](../adapters/GENERIC_EXTERNAL_EVENT_RECEIPT_ADAPTER.md)
- [docs/KNOWN_LIMITATIONS.md](../KNOWN_LIMITATIONS.md)

Example events:

- [examples/adapters/generic-external-event/ai-agent-action-event.json](../../examples/adapters/generic-external-event/ai-agent-action-event.json)
- [examples/adapters/generic-external-event/ai-agent-result-event.json](../../examples/adapters/generic-external-event/ai-agent-result-event.json)

Retained proof history:

- [docs/retention/milestones/MILESTONE_146.md](../retention/milestones/MILESTONE_146.md)
- [docs/retention/milestones/MILESTONE_147.md](../retention/milestones/MILESTONE_147.md)
- [docs/retention/milestones/MILESTONE_148.md](../retention/milestones/MILESTONE_148.md)
- [docs/reviews/AI_AGENT_EVENT_REVIEWER_DRY_RUN_M149.md](AI_AGENT_EVENT_REVIEWER_DRY_RUN_M149.md)

## Import Proposed Action

Run from the repository root:

```bash
action_receipt=/tmp/atlas-m150-ai-agent-action.receipt.json

./tools/atlas/bin/atlas receipt import-generic-event \
  examples/adapters/generic-external-event/ai-agent-action-event.json \
  --out "$action_receipt"
```

Expected output:

```text
receipt: /tmp/atlas-m150-ai-agent-action.receipt.json
```

## Verify Proposed Action Receipt

```bash
./tools/atlas/bin/atlas receipt verify "$action_receipt"
```

Expected output includes:

```text
receipt: ok
This receipt validates as a metadata-only proof record.
It does not prove external artifact availability, human intent, legal compliance, or artifact correctness.
```

## Import Reported Result

```bash
result_receipt=/tmp/atlas-m150-ai-agent-result.receipt.json
prev_hash="$(jq -r '.event_hash' "$action_receipt")"

./tools/atlas/bin/atlas receipt import-generic-event \
  examples/adapters/generic-external-event/ai-agent-result-event.json \
  --prev-hash "$prev_hash" \
  --out "$result_receipt"
```

Expected output:

```text
receipt: /tmp/atlas-m150-ai-agent-result.receipt.json
```

## Verify Reported Result Receipt

```bash
./tools/atlas/bin/atlas receipt verify "$result_receipt"
```

Expected output includes:

```text
receipt: ok
This receipt validates as a metadata-only proof record.
It does not prove external artifact availability, human intent, legal compliance, or artifact correctness.
```

## Replay Linked Receipts

```bash
./tools/atlas/bin/atlas receipt replay \
  "$action_receipt" \
  "$result_receipt"
```

Expected output includes:

```text
receipt replay: ok
receipts: 2
ledger binding: ok prev_hash -> event_hash
metadata-only boundary: ok
This replay verifies receipt hashes and provided-order prev_hash linkage only.
It does not prove external artifact availability, human intent, legal compliance, artifact correctness, authorization, or production readiness.
```

JSON replay check:

```bash
./tools/atlas/bin/atlas receipt replay \
  "$action_receipt" \
  "$result_receipt" \
  --json | jq -e '
    .schema_version == "atlas.receipt_replay.v1" and
    .status == "ok" and
    .metadata_only == true and
    .raw_artifacts_embedded == false and
    .receipt_count == 2 and
    .ledger_binding.status == "ok"
  '
```

Expected output:

```text
true
```

## Security Boundary Evidence

M148 is the retained fail-closed security regression for this profile:

- [../retention/milestones/MILESTONE_148.md](../retention/milestones/MILESTONE_148.md)

M148 proves that unsafe AI-agent event imports fail closed before this proof
package is promoted. It covers rejection of:

- `raw_prompt`
- `raw_model_output`
- `raw_response`
- `system_prompt`
- `tool_output_body`
- `tool_call_raw`
- `Authorization: Bearer`
- `token=`
- `password=`
- `secret=`
- `BEGIN PRIVATE KEY`
- `metadata_only=false`
- `raw_artifacts_embedded=true`
- missing `known_limitations`
- missing actor or AI-agent identity
- `approval_required=true` without approval references

Minimal local rejection check for a raw prompt marker:

```bash
bad_event=/tmp/atlas-m150-ai-agent-raw-prompt.json
bad_receipt=/tmp/atlas-m150-ai-agent-raw-prompt.receipt.json

jq '. + {raw_prompt: "raw prompt body must not enter receipts"}' \
  examples/adapters/generic-external-event/ai-agent-action-event.json \
  > "$bad_event"

if ./tools/atlas/bin/atlas receipt import-generic-event "$bad_event" \
  --out "$bad_receipt"; then
  printf 'unexpected import success\n' >&2
  exit 1
fi

test ! -e "$bad_receipt"
```

Expected failure text includes:

```text
generic external event contains forbidden raw-content marker
```

## Public Reviewer Dry-Run

M149 records the public clone review path that this package summarizes:

- [AI_AGENT_EVENT_REVIEWER_DRY_RUN_M149.md](AI_AGENT_EVENT_REVIEWER_DRY_RUN_M149.md)

M149 showed that a reviewer could clone the public repository, run the
AI-agent import, verify, and replay path, inspect the metadata-only boundary,
and run the public export check without private context.

## What Atlas Proves

For the reviewed public path, Atlas proves:

- the AI-agent examples are valid `generic.external_event.v1` imports;
- the existing generic adapter can produce AI-agent event receipts;
- generated receipts verify with `atlas receipt verify`;
- linked proposed-action and result receipts replay with `atlas receipt replay`;
- replay preserves `metadata_only=true`;
- replay preserves `raw_artifacts_embedded=false`;
- unsafe raw prompt, model output, response, system prompt, tool body, raw tool
  call, token, password, secret, and private-key markers reject;
- rejected unsafe imports do not create the requested output receipt;
- public documentation points to known limitations and non-guarantees.

## What Atlas Does Not Prove

This proof package does not prove:

- model correctness;
- source-runtime truth;
- that an AI agent was authorized to act;
- that Atlas approved an action;
- tool execution safety;
- external artifact availability;
- artifact correctness;
- human intent;
- legal compliance;
- runtime safety;
- production approval;
- external audit;
- certification.

## Known Limitations

- The example AI-agent events are synthetic.
- Atlas does not call a model provider, local model API, webhook, scanner,
  browser, backend, or source system.
- Atlas does not execute agent proposals or reported actions.
- Atlas does not make approval decisions for AI agents.
- Atlas does not validate source-runtime truth or model output correctness.
- Receipt replay verifies local receipt hashes and caller-provided chain order.
- Broad secret-marker scans can include expected test fixtures and guardrail
  references; reviewers should distinguish those from retained raw artifacts.
- This package is a reviewer-facing proof bundle, not a production readiness,
  compliance, audit, or certification claim.

## Reviewer Checklist

- Read `docs/TRY_AI_AGENT_EVENT_RECEIPTS.md`.
- Read `docs/adapters/AI_AGENT_EVENT_RECEIPT_PROFILE.md`.
- Read `docs/adapters/GENERIC_EXTERNAL_EVENT_RECEIPT_ADAPTER.md`.
- Read `docs/KNOWN_LIMITATIONS.md`.
- Inspect the action and result example JSON files.
- Import the proposed-action event.
- Verify the proposed-action receipt.
- Import the reported-result event with `--prev-hash`.
- Verify the reported-result receipt.
- Replay both receipts together.
- Confirm replay reports `metadata-only boundary: ok`.
- Review M148 for fail-closed unsafe-input coverage.
- Review M149 for public clone dry-run evidence.
- Confirm no agent runtime, tool execution, network collector, second adapter,
  database, server, or web UI is added by this package.

## Boundary

- AI agents are event sources only.
- Atlas is verifier only.
- Human and policy remain authority.
- No agent runtime is added.
- No tool execution is added.
- No network collector is added.
- No database, server, or web UI is added.
- No second adapter is added.
- No receipt semantics are changed.
- No receipt verification, replay, canonicalization, release, or reviewer gate
  is weakened.
- No external audit, certification, legal compliance, runtime safety, artifact
  correctness, or production approval claim is made.
