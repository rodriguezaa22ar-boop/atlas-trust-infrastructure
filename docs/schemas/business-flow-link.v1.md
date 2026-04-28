# Schema Contract: atlas.business_flow_link.v1

## Purpose

`atlas.business_flow_link.v1` describes an operation-scoped NDJSON record that
links a global business flow to an Atlas operation. It is written when
`atlas flow link-evidence`, `atlas flow link-finding`, or
`atlas flow link-validation` first connects a flow to operation context.

The record lives at:

```text
sessions/<operation>/business_flows.ndjson
```

Each line is one JSON object.

## Required Fields

| Field | Type | Meaning |
| --- | --- | --- |
| `schema_version` | string | Must be `atlas.business_flow_link.v1`. |
| `flow_id` | string | Stable flow ID. |
| `flow_slug` | string | Flow slug from the global record. |
| `flow_name` | string | Flow display name from the global record. |
| `operation` | string | Active operation slug. |
| `target` | string | Active operation target. |
| `linked_at` | string | Timestamp when the flow was linked to the operation. |
| `linked_by` | string | Tool or actor that created the link. |
| `metadata_only` | boolean | Must be `true`. |

## Cardinality

The same `flow_id` should appear at most once for the same `operation` in
`business_flows.ndjson`. Additional evidence, finding, validation, and approval
references for the flow belong in `flow_evidence.ndjson`,
`flow_findings.ndjson`, `flow_validation.ndjson`, and `flow_approvals.ndjson`.

## Forbidden Content

Operation flow links must not include:

- secrets
- raw evidence bodies
- request or response bodies
- customer records
- credential material
- private keys
- authorization headers
- session cookies

## Verification Rules

A verifier should fail when:

- `schema_version` is not `atlas.business_flow_link.v1`.
- Required fields are missing.
- `metadata_only` is not `true`.
- The referenced global flow record is missing.
- The operation slug does not match the active operation being verified.
- The target does not match the operation target.
- A forbidden raw-content marker appears in any value.

## Non-Goals

- This link does not copy evidence, finding bodies, or validation details.
- This link does not replace evidence, finding, or validation links.
- This link does not prove a packet is current.
