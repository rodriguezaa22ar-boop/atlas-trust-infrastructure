# Schema Contract: atlas.flow_approval_link.v1

## Purpose

`atlas.flow_approval_link.v1` describes an operation-scoped NDJSON record that
links an Atlas Business Flow Evidence record to an existing Atlas operation
approval without copying the approval reason, reviewer rationale, operator
notes, command output, or raw evidence.

Records are written by:

```bash
atlas flow link-approval <flow> <capability>
```

to:

```text
sessions/<operation>/flow_approvals.ndjson
```

The command links the latest approved operation approval for the named
capability and active target.

## Required Fields

| Field | Type | Meaning |
| --- | --- | --- |
| `schema_version` | string | Must be `atlas.flow_approval_link.v1`. |
| `flow_id` | string | Stable flow ID. |
| `flow_slug` | string | Flow slug. |
| `operation` | string | Active operation slug. |
| `target` | string | Active operation target. |
| `approval_ref` | string | Stable metadata reference, formatted as `approval:<capability>:<approval_ts>`. |
| `capability` | string | Approved capability, for example `safe-validation`. |
| `tier` | string | Capability tier at approval time. |
| `status` | string | Approval status. Must be `approved` for this link type. |
| `approved_by` | string | Approving actor metadata. |
| `approval_ts` | string | Timestamp of the linked approval record. |
| `linked_at` | string | UTC link timestamp. |
| `linked_by` | string | Linking actor or tool. |
| `notes` | string | Metadata-only boundary note. |
| `metadata_only` | boolean | Must be `true`. |

## Forbidden Fields

Records must not include:

- approval reasons
- reviewer rationale
- operator notes
- validation plan bodies
- command output
- raw evidence bodies
- request or response bodies
- customer records
- tokens
- credentials
- private keys
- session cookies
- authorization headers

## Verification Rules

Business-flow packet verification checks that linked approval records still
exist in the active operation, that packet references include the linked
approval reference, and that current approval metadata still matches the linked
snapshot. Drift reports `stale`; a missing linked approval reports `blocked`.

## Non-Goals

- This link is not an approval packet.
- This link is not legal or compliance approval.
- This link does not embed approval reasons or operator notes.
