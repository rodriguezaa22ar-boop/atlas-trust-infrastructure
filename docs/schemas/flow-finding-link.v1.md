# Schema Contract: atlas.flow_finding_link.v1

## Purpose

`atlas.flow_finding_link.v1` describes an operation-scoped NDJSON record that
links an Atlas Business Flow Evidence record to an existing Atlas finding
without copying raw finding bodies, impact text, recommendation text, or raw
evidence.

Records are written by:

```bash
atlas flow link-finding <flow> <finding-id>
```

to:

```text
sessions/<operation>/flow_findings.ndjson
```

## Required Fields

| Field | Type | Meaning |
| --- | --- | --- |
| `schema_version` | string | Must be `atlas.flow_finding_link.v1`. |
| `flow_id` | string | Stable flow ID. |
| `flow_slug` | string | Flow slug. |
| `operation` | string | Active operation slug. |
| `target` | string | Active operation target. |
| `finding_id` | string | Existing Atlas finding ID in the active operation. |
| `title` | string | Finding title metadata. |
| `level` | string | Finding level at link time. |
| `severity` | string | Finding severity at link time. |
| `confidence` | string | Finding confidence at link time. |
| `status` | string | Finding status at link time. |
| `finding_created_at` | string | Finding creation timestamp when available. |
| `finding_updated_at` | string | Latest finding update timestamp when available. |
| `linked_at` | string | UTC link timestamp. |
| `linked_by` | string | Linking actor or tool. |
| `notes` | string | Metadata-only boundary note. |
| `metadata_only` | boolean | Must be `true`. |

## Forbidden Fields

Records must not include:

- raw finding bodies
- impact bodies
- recommendation bodies
- raw evidence bodies
- request or response bodies
- customer records
- tokens
- credentials
- private keys
- session cookies
- authorization headers

## Verification Rules

Business-flow packet verification checks that linked finding IDs still exist,
that packet references include the linked finding IDs, and that current finding
metadata has not drifted from the linked snapshot. Drift reports `stale`; a
missing linked finding reports `blocked`.

## Non-Goals

- This link is not a finding export.
- This link is not a compliance attestation.
- This link does not embed remediation details or sensitive business context.
