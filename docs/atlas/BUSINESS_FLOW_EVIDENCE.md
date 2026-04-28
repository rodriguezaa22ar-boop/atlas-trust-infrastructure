# Atlas Business Flow Evidence

## Purpose

Atlas Business Flow Evidence is a metadata-only model for linking
business-critical processes to Atlas evidence, findings, validation, approvals,
reports, and retention artifacts without storing secrets or raw business data.

It extends Atlas from security operation evidence toward business-process
assurance while preserving the same core rule:

```text
Atlas stores references and proofs, not sensitive business content.
```

## What A Business Flow Is

A business flow is a process that matters to an organization and can be
reviewed, tested, validated, or retained.

Examples:

- customer signup
- login and authentication
- payment checkout
- password reset
- employee onboarding
- vendor onboarding
- support ticket escalation
- admin approval workflow
- data export
- security assessment closeout
- release approval
- production deployment
- incident review
- accepted-risk review

The flow record describes the process and links it to Atlas artifacts. It does
not embed the raw process content.

## Core Model

Business-flow evidence is referential evidence.

It may point to:

- operation records
- evidence IDs
- finding IDs
- validation plan IDs
- approval records
- reports
- handoff packets
- closeout manifests
- audit packets
- archive packets
- release packets
- freshness state
- known limitations

It must not include raw business data, request/response bodies, customer
records, secrets, tokens, card data, session contents, or credential material.

## Allowed Metadata

Business-flow records may include:

- flow ID
- flow name
- flow type
- owner
- criticality
- environment
- scope status
- system names or aliases
- data class labels
- control objective names
- evidence IDs
- finding IDs
- validation IDs
- approval IDs
- artifact paths
- SHA-256 hashes
- freshness status
- operation links
- retention packet links
- timestamps
- known limitations

Allowed data class labels include values such as:

- email
- account_metadata
- billing_status_reference
- authentication_state
- subscription_status_reference
- support_ticket_metadata
- deployment_metadata
- audit_metadata

These labels describe the class of data involved. They must not contain the
data itself.

## Forbidden Content

Business-flow evidence must never include:

- passwords
- API keys
- tokens
- private keys
- raw packet captures
- raw database rows
- raw customer records
- full request bodies
- full response bodies
- credit card data
- SSNs
- session cookies
- authorization headers
- private business documents
- credential material
- unredacted logs
- exploit payloads

The first verification pass should reject obvious secret-bearing markers such
as:

```text
password=
passwd=
api_key=
secret=
token=
authorization:
bearer
set-cookie:
private key
BEGIN RSA
BEGIN OPENSSH
session=
cookie=
```

This denylist is a guardrail, not a complete data-loss-prevention system.

## File-Backed Direction

Business-flow evidence should stay file-backed like the rest of Atlas.

Global flow records:

```text
state/atlas/flows/<flow-slug>.env
```

Operation-specific flow links:

```text
sessions/<operation>/business_flows.ndjson
sessions/<operation>/flow_evidence.ndjson
sessions/<operation>/flow_findings.ndjson
sessions/<operation>/flow_validation.ndjson
sessions/<operation>/flow_packets/<packet-name>.md
sessions/<operation>/flow_packets_json/<packet-name>.json
```

Atlas should not introduce SQLite, hidden caches, remote state, or a web-backed
business-flow store for the first version.

## Current Runtime Slice

The first runtime slice implements global metadata-only flow records:

```bash
atlas flow add <flow-name>
atlas flow list
atlas flow show <flow>
atlas flow link-evidence <flow> <evidence-id>
atlas flow link-finding <flow> <finding-id>
atlas flow link-validation <flow> <validation-id>
atlas flow link-approval <flow> <capability>
atlas flow packet [--json] <flow> [packet-name]
atlas flow verify [--json] <flow> [packet-name]
```

Implemented records are written to:

```text
state/atlas/flows/<flow-slug>.env
sessions/<operation>/business_flows.ndjson
sessions/<operation>/flow_evidence.ndjson
sessions/<operation>/flow_findings.ndjson
sessions/<operation>/flow_validation.ndjson
sessions/<operation>/flow_approvals.ndjson
sessions/<operation>/flow_packets/<packet-name>.md
sessions/<operation>/flow_packets_json/<packet-name>.json
```

Implemented schema contracts:

- [`atlas.business_flow.v1`](../schemas/business-flow-record.v1.md)
- [`atlas.business_flow_link.v1`](../schemas/business-flow-link.v1.md)
- [`atlas.flow_evidence_link.v1`](../schemas/flow-evidence-link.v1.md)
- [`atlas.flow_finding_link.v1`](../schemas/flow-finding-link.v1.md)
- [`atlas.flow_validation_link.v1`](../schemas/flow-validation-link.v1.md)
- [`atlas.flow_approval_link.v1`](../schemas/flow-approval-link.v1.md)
- [`atlas.business_flow_packet.v1`](../schemas/business-flow-packet.v1.md)
- [`atlas.business_flow_verify.v1`](../schemas/business-flow-verify.v1.md)

`atlas flow link-evidence` requires an active operation and an existing evidence
ID in that operation. The link records metadata such as evidence ID, kind,
retained path, SHA-256, classification, and redaction state. It does not copy
the evidence artifact and does not store the evidence body or original source
path.

`atlas flow link-finding` requires an active operation and an existing finding
ID in that operation. The link stores only finding metadata such as finding ID,
title, level, severity, confidence, status, timestamps, and link metadata. It
does not copy impact bodies, recommendation bodies, raw evidence, or sensitive
business context.

`atlas flow link-validation` requires an active operation and an existing
validation plan ID in that operation. The link stores only validation metadata
such as validation ID, lane, capability, status, linked finding ID, result
status, timestamps, and link metadata. It does not copy validation reasons, plan
bodies, session contents, command output, or raw evidence.

`atlas flow link-approval` requires an active operation and an approved
operation capability such as `safe-validation`. The link stores only the latest
approved capability metadata for the active target: capability, tier, approval
status, approved-by value, approval timestamp, and link metadata. It does not
copy approval reasons, reviewer rationale, operator notes, command output, or
raw evidence.

`atlas flow packet` requires an active operation and an existing business-flow
evidence link in that operation. By default it writes a metadata-only Markdown
packet with flow identity, operation metadata, data class labels, system
aliases, control objective labels, evidence IDs, retained evidence paths,
SHA-256 hashes, classification, redaction state, finding references, validation
references, approval references, freshness metadata, and known limitations. With
`--json`, it writes the same metadata-only contract as machine-readable JSON under
`flow_packets_json/`.

`atlas flow verify` requires an active operation and verifies the current
metadata-only Markdown packet against the flow record, operation link, evidence
links, finding links, validation links, approval links, retained evidence
records, retained evidence files, hashes, freshness timestamps, and
forbidden-content guardrails. With `--json`, it verifies the JSON packet and emits
`atlas.business_flow_verify.v1`.

This slice does not implement retention links or flow trust-chain integration
yet. Readiness integration is implemented as optional and non-blocking.

## Flow Record Contract

A minimal flow record should describe the flow without storing raw flow content.

Example:

```bash
SCHEMA_VERSION=atlas.business_flow.v1
FLOW_ID=flow_customer_signup
FLOW_SLUG=customer-signup
FLOW_NAME=customer-signup
FLOW_TYPE=customer_onboarding
OWNER=product
CRITICALITY=high
ENVIRONMENT=staging
SCOPE_STATUS=in-scope
DATA_CLASSES=email,account_metadata,billing_reference
SYSTEMS=web_app,auth_service,user_database,email_service
CONTROL_OBJECTIVES=authentication_required,input_validation,rate_limiting,audit_logging,pii_minimization
CREATED_AT=2026-04-27T12:00:00Z
UPDATED_AT=2026-04-27T12:00:00Z
SOURCE_TOOL=atlas
MODE=business_flow
METADATA_ONLY=true
```

## Evidence Links

Flow evidence links should reference existing Atlas evidence records.

Example:

```json
{
  "schema_version": "atlas.flow_evidence_link.v1",
  "flow_id": "flow_customer_signup",
  "flow_slug": "customer-signup",
  "operation": "customer-signup-review",
  "target": "demo-web-app",
  "evidence_id": "ev_20260427_001",
  "kind": "redacted_report",
  "evidence_path": "sessions/customer-signup-review/evidence/ev_20260427_001",
  "evidence_sha256": "abc123...",
  "evidence_classification": "public",
  "evidence_redacted": true,
  "linked_at": "2026-04-27T12:10:00Z",
  "linked_by": "atlas",
  "notes": "Metadata-only reference. Raw evidence not embedded.",
  "metadata_only": true
}
```

Rules:

- Requires an active operation.
- The referenced evidence ID must exist.
- The link must not copy raw evidence content.
- The link should write a ledger event.
- The link should carry enough metadata for packet verification.

## Finding Links

Flow finding links should reference existing Atlas findings without exporting
finding bodies.

Example:

```json
{
  "schema_version": "atlas.flow_finding_link.v1",
  "flow_id": "flow_customer_signup",
  "flow_slug": "customer-signup",
  "operation": "customer-signup-review",
  "target": "demo-web-app",
  "finding_id": "finding_20260427T120000Z",
  "title": "Signup MFA gap",
  "level": "observed",
  "severity": "medium",
  "confidence": "high",
  "status": "open",
  "finding_created_at": "2026-04-27T12:00:00Z",
  "finding_updated_at": "2026-04-27T12:00:00Z",
  "linked_at": "2026-04-27T12:15:00Z",
  "linked_by": "atlas",
  "notes": "Metadata-only reference. Finding impact and recommendation bodies are not embedded.",
  "metadata_only": true
}
```

Rules:

- Requires an active operation.
- The referenced finding ID must exist.
- The link must not copy finding impact or recommendation bodies.
- The link should write a ledger event.

## Validation Links

Flow validation links should reference existing Atlas validation plans without
exporting plan bodies or session contents.

Example:

```json
{
  "schema_version": "atlas.flow_validation_link.v1",
  "flow_id": "flow_customer_signup",
  "flow_slug": "customer-signup",
  "operation": "customer-signup-review",
  "target": "demo-web-app",
  "validation_id": "vp_20260427T121000Z",
  "lane": "validate",
  "capability": "safe-validation",
  "status": "planned",
  "finding_id": "finding_20260427T120000Z",
  "result_status": null,
  "validation_created_at": "2026-04-27T12:10:00Z",
  "validation_updated_at": "2026-04-27T12:10:00Z",
  "linked_at": "2026-04-27T12:16:00Z",
  "linked_by": "atlas",
  "notes": "Metadata-only reference. Validation reason, plan body, and session contents are not embedded.",
  "metadata_only": true
}
```

Rules:

- Requires an active operation.
- The referenced validation ID must exist.
- The link must not copy validation reason, plan body, session contents, or raw
  evidence.
- The link should write a ledger event.

## Flow Packet

`atlas flow packet <flow> [packet-name]` generates a metadata-only Markdown
packet under:

```text
sessions/<operation>/flow_packets/<packet-name>.md
```

`atlas flow packet --json <flow> [packet-name]` generates the JSON parity
packet under:

```text
sessions/<operation>/flow_packets_json/<packet-name>.json
```

The packet includes:

- flow identity
- owner
- criticality
- environment
- scope status
- systems
- data classes
- control objectives
- evidence references
- retained evidence paths
- evidence SHA-256 hashes
- classification and redaction state
- finding references
- validation references
- approval references
- freshness state
- known limitations
- SHA-256 anchors where available

Retention references remain empty metadata structures or known limitations until
those link types exist.

The packet must not include:

- raw evidence body
- tokens
- passwords
- packet captures
- request or response bodies
- customer data
- private documents
- credential material

## Flow Verification

`atlas flow verify <flow> [packet-name]` and
`atlas flow verify --json <flow> [packet-name]` check:

- flow record exists
- packet exists
- packet schema marker is present
- packet is marked metadata-only
- packet does not claim raw evidence embedding
- packet operation, target, and flow ID match the current active operation and
  flow record
- packet flow ID matches the flow record
- linked evidence IDs still exist
- linked evidence hashes still match
- linked finding IDs still exist
- linked finding metadata is current
- linked validation IDs still exist
- linked validation metadata is current
- linked approval records still exist
- linked approval metadata still matches the linked snapshot
- retained evidence files still exist
- retained evidence file hashes still match evidence records
- packet freshness is current
- forbidden raw-content markers are absent

Verification fails closed on missing packets, missing links, stale packets,
missing retained files, hash mismatches, and forbidden raw-content markers.
Retention verification can be added after those link types exist.

## Freshness

Initial freshness states:

- `missing`: no packet exists for the flow.
- `current`: packet is newer than linked material events.
- `stale`: linked evidence, findings, validation, or approvals changed after
  packet generation.
- `blocked`: linked artifacts are missing, hashes mismatch, or forbidden
  content is detected.

First implementation rule:

```text
If any linked evidence, finding, validation, or approval event is newer than the
flow packet generation time, the flow packet is stale.
```

More complex graph freshness can come later.

## Command Direction

The first runtime command set should stay small:

```bash
atlas flow add <flow-name>
atlas flow list
atlas flow show <flow>
atlas flow link-evidence <flow> <evidence-id>
atlas flow link-finding <flow> <finding-id>
atlas flow link-validation <flow> <validation-id>
atlas flow link-approval <flow> <capability>
atlas flow packet [--json] <flow> [packet-name]
atlas flow verify [--json] <flow> [packet-name]
```

Later commands may add:

```bash
atlas flow trust-chain <flow>
```

Do not add automatic business-flow discovery in the first implementation.

## Readiness Position

Business Flow Evidence is optional at the current maturity stage.

`atlas v1 status` and `atlas production status` now include Business Flow
Evidence as an optional non-blocking pillar/gate. The integration is
intentionally conservative: it reports command, packet, verification, record,
and active-operation link visibility, but it does not fail strict readiness
while the model is still being refined.

It must not become required for:

```bash
atlas v1 status --strict
atlas production status --strict
```

until flow records, flow packets, verification, negative tests, and metadata-only
guardrails are stable.

Current readiness states:

- `ready`: flow commands, packet generation, and packet verification are
  available and covered by tests.
- `planned`: the optional pillar is explicitly marked planned or not fully
  enabled.
- `disabled`: explicitly disabled by configuration.

Future promoted states may add `warning` or `blocked` for active operations with
stale/missing flow packets, missing linked evidence, missing linked findings,
missing linked validation records, hash mismatches, or forbidden-content
markers. Those states should not become blocking until the Business Flow
Evidence pillar is intentionally promoted from optional to required.

## Known Limitations

- This model does not prove the business process is correct by itself.
- This model does not validate payment processors, banks, or third-party
  settlement outside retained metadata.
- This model does not replace compliance audits.
- Forbidden-marker scanning is a guardrail, not complete DLP.
- Raw customer or payment data must be retained outside Atlas under the
  organization's own data-handling rules if retention is required.

## Non-Goals

- Web UI.
- SQL migration.
- Remote sync.
- Automatic business-flow discovery.
- AI-generated flow assessment.
- Payment card testing.
- Storing raw business data.
- Storing customer records.
- Storing secrets.

## Bottom Line

Atlas Business Flow Evidence maps business-critical workflows to evidence,
findings, validation, approvals, and retention packets without storing the
sensitive flow content.

It belongs inside Atlas as an optional module because it depends on Atlas trust
primitives:

```text
scope + evidence + findings + validation + retention + verification
```
