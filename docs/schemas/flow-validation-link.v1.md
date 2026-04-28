# Schema Contract: atlas.flow_validation_link.v1

## Purpose

`atlas.flow_validation_link.v1` describes an operation-scoped NDJSON record that
links an Atlas Business Flow Evidence record to an existing Atlas validation
plan without copying the validation reason, plan body, session contents, or raw
evidence.

Records are written by:

```bash
atlas flow link-validation <flow> <validation-id>
```

to:

```text
sessions/<operation>/flow_validation.ndjson
```

## Required Fields

| Field | Type | Meaning |
| --- | --- | --- |
| `schema_version` | string | Must be `atlas.flow_validation_link.v1`. |
| `flow_id` | string | Stable flow ID. |
| `flow_slug` | string | Flow slug. |
| `operation` | string | Active operation slug. |
| `target` | string | Active operation target. |
| `validation_id` | string | Existing Atlas validation plan ID in the active operation. |
| `lane` | string | Validation lane at link time. |
| `capability` | string | Capability classification at link time. |
| `status` | string | Validation status at link time. |
| `finding_id` | string or null | Linked finding ID when the validation references one. |
| `result_status` | string or null | Validation result status when available. |
| `validation_created_at` | string | Validation creation timestamp when available. |
| `validation_updated_at` | string | Latest validation update timestamp when available. |
| `linked_at` | string | UTC link timestamp. |
| `linked_by` | string | Linking actor or tool. |
| `notes` | string | Metadata-only boundary note. |
| `metadata_only` | boolean | Must be `true`. |

## Forbidden Fields

Records must not include:

- validation reasons
- plan bodies
- session contents
- raw evidence bodies
- request or response bodies
- customer records
- tokens
- credentials
- private keys
- session cookies
- authorization headers

## Verification Rules

Business-flow packet verification checks that linked validation IDs still exist,
that packet references include the linked validation IDs, and that current
validation metadata has not drifted from the linked snapshot. Drift reports
`stale`; a missing linked validation reports `blocked`.

## Non-Goals

- This link is not a validation packet.
- This link is not an approval record.
- This link does not embed command output or validation session artifacts.
