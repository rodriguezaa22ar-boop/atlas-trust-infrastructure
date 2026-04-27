# Schema Contract: atlas.business_flow_packet.v1

## Purpose

`atlas.business_flow_packet.v1` describes the planned machine-readable companion
to an Atlas Business Flow Evidence packet.

The packet is metadata-only. It records which business flow was reviewed, which
Atlas artifacts support the review, what validation or findings exist, and
whether the packet is current.

This is a design contract for the planned optional Business Flow Evidence module.
It is not yet emitted by a stable Atlas command.

## Required Fields

| Field | Type | Meaning |
| --- | --- | --- |
| `schema_version` | string | Must be `atlas.business_flow_packet.v1`. |
| `packet_id` | string | Stable packet ID. |
| `generated_at` | string | UTC timestamp. |
| `operation` | string | Atlas operation name or slug. |
| `target` | string | Atlas target name. |
| `flow` | object | Flow identity and metadata. |
| `systems` | array of strings | System aliases involved in the flow. |
| `data_classes` | array of strings | Data class labels involved in the flow. |
| `control_objectives` | array of strings | Control objective labels. |
| `evidence_refs` | array of objects | Evidence ID, kind, hash, and path references. |
| `findings_refs` | array of strings | Linked finding IDs. |
| `validation_refs` | array of strings | Linked validation IDs. |
| `approval_refs` | array of strings | Linked approval references. |
| `retention_refs` | object | Linked handoff, closeout, audit, archive, or release packet paths. |
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

`retention_refs` may include:

- `report`
- `handoff_packet`
- `closeout_manifest`
- `audit_packet`
- `archive_packet`
- `release_packet`

Values should be paths or packet names, not embedded packet bodies.

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

`atlas flow verify` should eventually check:

- packet exists
- `schema_version` matches
- `metadata_only` is `true`
- flow record exists
- packet flow ID matches flow record
- linked evidence IDs exist
- linked evidence hashes still match
- linked finding IDs exist
- linked validation IDs exist
- linked retention references exist when required
- freshness is current unless non-strict verification allows stale state
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
automation.

## Non-Goals

- This packet is not a raw evidence bundle.
- This packet is not a payment or banking record.
- This packet is not a compliance certification.
- This packet is not a substitute for third-party audit evidence.

