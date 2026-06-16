# External Project Receipts

## Purpose

M190 defines a small external-project receipt pilot on top of the existing
`generic.external_event.v1` importer and `atlas.receipt.v1` verifier.

The goal is to make actions that originate outside the Atlas core repository
reviewable as metadata-only proof receipts without turning Atlas into the
source system, action executor, approval authority, scanner, CI/CD runtime, or
business-system database.

## Model

An external-project receipt starts with a local event JSON file supplied by an
operator or reviewer:

```text
external project event metadata -> atlas receipt import-generic-event
-> atlas receipt verify -> atlas receipt replay
```

The event file is a local metadata envelope. It may describe who requested an
action, which project or system the action belongs to, which capability or
policy was relevant, whether approval was required, which approval reference
was used, and which evidence or artifact references were emitted.

It must not embed raw logs, raw prompts, raw model outputs, terminal buffers,
request bodies, response bodies, packet captures, customer data, payment data,
private business records, private target records, credentials, tokens, private
keys, session cookies, Authorization headers, or unredacted evidence bodies.

## Event Profile

M190 intentionally reuses `generic.external_event.v1` instead of adding a
parallel event schema. External-project fields are represented as metadata
references:

| External-project concept | `generic.external_event.v1` field |
| --- | --- |
| `schema_version` | `schema_version` |
| `event_type` | `event_type` |
| `observed_at` | `observed_at` |
| `actor_ref` | `actor` and `external_project://actor/...` evidence ref |
| `project_ref` | `subject.ref` and `external_project://project/...` evidence ref |
| `system_ref` | `external_project://system/...` evidence ref |
| `action` | `event_type` and `external_project://action/...` evidence ref |
| `capability` | `external_project://capability/...` evidence ref |
| `policy_ref` | `external_project://policy/...` evidence ref |
| `approval_required` | `external_project://approval_required/...` evidence ref |
| `approval_ref` | `approval_refs[]` |
| `evidence_refs` | `evidence_refs[]` |
| `artifact_refs` | `artifact_refs[]` |
| `input_hashes` | `sha256:input:<digest>` evidence refs |
| `output_hashes` | `sha256:output:<digest>` evidence refs |
| `known_limitations` | `known_limitations[]` |
| `metadata_only` | `metadata_only=true` |
| `raw_artifacts_embedded` | `raw_artifacts_embedded=false` |

This profile is compatible with the existing import command:

```bash
./tools/atlas/bin/atlas receipt import-generic-event \
  examples/receipt/external-project/minimal-event.json \
  --out /tmp/atlas-external-project-receipt.json
```

## Receipt Shape

The generated receipt remains a normal `atlas.receipt.v1` record.

External-project receipt review should interpret the fields this way:

| Review concept | `atlas.receipt.v1` field |
| --- | --- |
| `schema_version` | `schema_version` |
| `event_hash` | `event_hash` |
| `prev_hash` | `prev_hash` |
| `receipt_hash` | `receipt_hash` |
| `source_event_ref` | first `evidence_refs[]` entry, normally the source event path |
| `metadata_only` | `metadata_only=true` |
| `raw_artifacts_embedded` | `raw_artifacts_embedded=false` |
| `verification_summary` | output from `atlas receipt verify --json` |
| `replay_notes` | output from `atlas receipt replay --json` plus `known_limitations[]` |
| `known_limitations` | `known_limitations[]` |

M190 does not change the `atlas.receipt.v1` schema, canonicalization, verifier,
or replay semantics. It documents and tests a reviewer-safe external-project
profile using the existing receipt engine.

## Verification

Reviewers can verify the committed fixture:

```bash
./tools/atlas/bin/atlas receipt verify \
  examples/receipt/external-project/minimal-receipt.json
```

Reviewers can also regenerate a receipt from the event fixture:

```bash
./tools/atlas/bin/atlas receipt import-generic-event \
  examples/receipt/external-project/minimal-event.json \
  --out /tmp/atlas-external-project-receipt.json

./tools/atlas/bin/atlas receipt verify /tmp/atlas-external-project-receipt.json
```

To test replay linkage, import a later external event with `--prev-hash` set to
the previous receipt's `event_hash`, then run:

```bash
./tools/atlas/bin/atlas receipt replay \
  /tmp/atlas-external-project-receipt-1.json \
  /tmp/atlas-external-project-receipt-2.json
```

## What Atlas Can Check

Atlas can check:

- event and receipt JSON validity;
- `metadata_only=true`;
- `raw_artifacts_embedded=false`;
- required metadata fields and known limitations;
- forbidden raw-content, secret, token, private keys, request-body,
  response-body, packet-capture, raw-prompt, and raw-output markers;
- deterministic `event_hash` and `receipt_hash`;
- caller-provided `prev_hash -> event_hash` chain order;
- verifier and replay output that stays metadata-only.

## What Atlas Does Not Prove

Atlas receipts do not prove:

- source-system truth;
- external project completeness;
- external artifact availability;
- action correctness;
- model correctness;
- artifact correctness;
- human intent;
- authorization by themselves;
- legal compliance;
- production approval;
- external audit completion;
- external certification;
- complete event coverage;
- tamper-proof storage or immutable infrastructure.

Human judgment remains required for business, security, legal, approval, and
deployment decisions.

## Non-Goals

M190 does not add a database, server, web UI, network collector, webhook,
source-system API client, scanner, CI/CD runner, approval workflow executor,
autonomous agent runtime, evidence lake, credential store, or action router.

M190 does not add live integrations, credentials, API calls, webhooks, network
collectors, mutation authority, runtime policy enforcement, automatic
approval, automatic escalation, or hidden source-of-truth state.
