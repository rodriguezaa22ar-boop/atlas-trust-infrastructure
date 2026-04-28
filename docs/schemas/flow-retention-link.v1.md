# Schema Contract: atlas.flow_retention_link.v1

## Purpose

`atlas.flow_retention_link.v1` describes an operation-scoped NDJSON record that
links an Atlas Business Flow Evidence record to an existing retained artifact
without copying the artifact body.

Records are written by:

```bash
atlas flow link-retention <flow> <kind> <path>
```

to:

```text
sessions/<operation>/flow_retention.ndjson
```

The retained artifact must already exist under the Atlas repository root so the
link remains replayable and hash-checkable.

## Allowed Kinds

- `report`
- `handoff`
- `closeout`
- `audit`
- `archive`
- `release`
- `review-packet`

## Required Fields

| Field | Type | Meaning |
| --- | --- | --- |
| `schema_version` | string | Must be `atlas.flow_retention_link.v1`. |
| `flow_id` | string | Stable flow ID. |
| `flow_slug` | string | Flow slug. |
| `operation` | string | Active operation slug. |
| `target` | string | Active operation target. |
| `retention_kind` | string | Kind of retained artifact. |
| `artifact_path` | string | Path to the retained artifact, relative to the Atlas repository root when possible. |
| `artifact_basename` | string | Filename-only metadata for reviewer display. |
| `artifact_sha256` | string | SHA-256 hash of the retained artifact at link time. |
| `linked_at` | string | UTC link timestamp. |
| `linked_by` | string | Linking actor or tool. |
| `notes` | string | Metadata-only boundary note. |
| `metadata_only` | boolean | Must be `true`. |

## Forbidden Fields

Records must not include:

- retained artifact contents
- report bodies
- packet bodies
- raw evidence bodies
- request or response bodies
- customer records
- approval reasons
- operator notes
- tokens
- credentials
- private keys
- session cookies
- authorization headers

## Verification Rules

Business-flow packet verification checks that linked retention references are
present in the packet, that linked artifact files still exist, and that current
artifact hashes match `artifact_sha256`.

Outcomes:

- `current`: packet reference exists and artifact hash matches.
- `stale`: link count changed or a retention link is newer than the packet.
- `blocked`: artifact is missing, hash mismatches, or the packet omits required
  retention metadata.

## Non-Goals

- This link is not a retention packet.
- This link does not embed retained artifact contents.
- This link does not prove legal compliance or third-party audit acceptance.
