# Schema Contract: atlas.business_flow_packet.v1

## Purpose

`atlas.business_flow_packet.v1` describes the Atlas Business Flow Evidence
packet contract.

The packet is metadata-only. It records which business flow was reviewed, which
Atlas artifacts support the review, what validation or findings exist, and
whether the packet is current.

The current `atlas flow packet` implementation emits a Markdown packet by
default. `atlas flow packet --json` emits a machine-readable JSON packet under
`sessions/<operation>/flow_packets_json/`. `atlas flow verify` verifies the
Markdown packet, and `atlas flow verify --json` verifies the JSON packet against
the active operation, flow record, evidence links, retained evidence files,
finding links, validation links, approval links, retention links, retained
artifact files, hashes, freshness, and metadata-only guardrails.

This packet depends on the stabilized record and link contracts:

- `atlas.business_flow.v1`
- `atlas.business_flow_link.v1`
- `atlas.flow_evidence_link.v1`
- `atlas.flow_finding_link.v1`
- `atlas.flow_validation_link.v1`
- `atlas.flow_approval_link.v1`
- `atlas.flow_retention_link.v1`

## Required Fields

| Field | Type | Meaning |
| --- | --- | --- |
| `schema_version` | string | Must be `atlas.business_flow_packet.v1`. |
| `packet_id` | string | Stable packet ID. |
| `generated_at` | string | UTC timestamp. |
| `operation` | string | Atlas operation name or slug. |
| `target` | string | Atlas target name. |
| `raw_evidence_embedded` | boolean | Must be `false`. |
| `flow` | object | Flow identity and metadata. |
| `systems` | array of strings | System aliases involved in the flow. |
| `data_classes` | array of strings | Data class labels involved in the flow. |
| `control_objectives` | array of strings | Control objective labels. |
| `evidence_refs` | array of objects | Evidence ID, kind, hash, and path references. |
| `findings_refs` | array of objects | Linked finding IDs and metadata snapshots. |
| `validation_refs` | array of objects | Linked validation IDs and metadata snapshots. |
| `approval_refs` | array of objects | Linked approval references and metadata snapshots. |
| `retention_refs` | object | Linked retained artifact references grouped by retention kind. |
| `freshness` | object | Current packet freshness state. |
| `known_limitations` | array of strings | Explicit limitations. |
| `metadata_only` | boolean | Must be `true`. |

## Flow Object

The `flow` object should contain:

| Field | Type | Meaning |
| --- | --- | --- |
| `flow_id` | string | Stable flow ID. |
| `flow_name` | string | Human-readable flow name. |
| `flow_type` | string | Flow category. |
| `owner` | string | Accountable owner. |
| `criticality` | string | `low`, `medium`, `high`, or `critical`. |
| `environment` | string | Environment label. |
| `scope_status` | string | Scope state. |

## Retention References

`retention_refs` may include arrays keyed by:

- `report`
- `handoff`
- `closeout`
- `audit`
- `archive`
- `release`
- `review-packet`

Values include artifact path, basename, SHA-256, link timestamp, and
`metadata_only: true`. They must not embed retained artifact contents.

## Freshness

Freshness statuses:

- `missing`: no packet exists.
- `current`: packet reflects linked material events.
- `stale`: linked material changed after packet generation.
- `blocked`: linked artifacts are missing, hashes mismatch, or forbidden
  content is detected.

## Forbidden Content

The packet must not include:

- raw evidence bodies
- tokens
- passwords
- packet captures
- request bodies
- response bodies
- customer records
- private documents
- credential material
- session cookies
- authorization headers
- private keys
- credit card data

The packet may include hashes and metadata references to redacted artifacts.

## Verification Rules

`atlas flow verify --json` checks:

- packet exists
- `schema_version` matches
- `metadata_only` is `true`
- `Raw Evidence Embedded` is `false`
- flow record exists
- packet flow ID matches flow record
- packet operation and target match the active operation
- linked evidence IDs exist
- linked evidence hashes still match
- linked finding IDs exist
- linked finding metadata still matches
- linked validation IDs exist
- linked validation metadata still matches
- linked approval records still exist
- linked approval metadata still matches
- linked retention references are present in the packet
- linked retention artifact files still exist
- linked retention artifact hashes still match
- retained evidence files exist
- retained evidence file hashes still match evidence records
- freshness is current
- forbidden raw-content markers are absent

## Markdown Parity

The Markdown packet should include the same core sections:

- Flow
- Systems
- Data Classes
- Control Objectives
- Evidence References
- Findings
- Validation
- Approvals
- Retention References
- Freshness
- Known Limitations

Markdown is for human review. JSON is for gates, replay, dashboards, and future
automation. The two formats must retain the same metadata-only boundary.

## Non-Goals

- This packet is not a raw evidence bundle.
- This packet is not a payment or banking record.
- This packet is not a compliance certification.
- This packet is not a substitute for third-party audit evidence.
