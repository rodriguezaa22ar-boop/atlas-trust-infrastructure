# Schema Contract: atlas.flow_evidence_link.v1

## Purpose

`atlas.flow_evidence_link.v1` describes an operation-scoped NDJSON record that
links a business flow to an existing Atlas evidence ID without copying raw
evidence content.

The record lives at:

```text
sessions/<operation>/flow_evidence.ndjson
```

Each line is one JSON object.

## Required Fields

| Field | Type | Meaning |
| --- | --- | --- |
| `schema_version` | string | Must be `atlas.flow_evidence_link.v1`. |
| `flow_id` | string | Stable flow ID. |
| `flow_slug` | string | Flow slug from the global record. |
| `operation` | string | Active operation slug. |
| `target` | string | Active operation target. |
| `evidence_id` | string | Existing Atlas evidence ID in the active operation. |
| `kind` | string | Evidence kind copied from the evidence record. |
| `evidence_path` | string | Retained evidence path from the evidence record. |
| `evidence_sha256` | string | SHA-256 from the evidence record. |
| `evidence_classification` | string | Classification label from the evidence record. |
| `evidence_redacted` | boolean | Redaction state from the evidence record. |
| `linked_at` | string | Timestamp when the link was created. |
| `linked_by` | string | Tool or actor that created the link. |
| `notes` | string | Metadata-only boundary note. |
| `metadata_only` | boolean | Must be `true`. |

## Metadata Boundary

`evidence_path` is a retained artifact path reference. The link must not include
the evidence body, source path, raw request, raw response, packet contents,
credential material, or customer records.

## Forbidden Content

Flow evidence links must not include:

- secrets
- passwords
- API keys
- tokens
- private keys
- session cookies
- authorization headers
- raw customer records
- payment card data
- request bodies
- response bodies
- raw evidence bodies

## Verification Rules

A verifier should fail when:

- `schema_version` is not `atlas.flow_evidence_link.v1`.
- Required fields are missing.
- `metadata_only` is not `true`.
- The referenced business flow is missing.
- The referenced operation does not match the active operation.
- The referenced evidence ID is missing from the active operation.
- `evidence_sha256` does not match the retained evidence record.
- The retained evidence file is missing.
- The retained evidence file hash no longer matches the evidence record.
- A forbidden raw-content marker appears in any value.

## Non-Goals

- This link is not an evidence bundle.
- This link is not a raw evidence retention format.
- This link is not a compliance certification.
