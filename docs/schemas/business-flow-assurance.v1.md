# Schema Contract: atlas.business_flow_assurance.v1

## Purpose

`atlas.business_flow_assurance.v1` describes the read-only, machine-readable
business-process assurance view emitted by:

```bash
atlas flow assurance --json <flow> [packet-name]
```

The view deepens Business Flow Evidence by interpreting existing metadata-only
flow records, operation links, evidence links, finding links, validation links,
approval links, retention links, and packet verification state. It does not
store raw business data and does not make Business Flow Evidence a required v1
or production gate.

## Required Fields

| Field | Type | Meaning |
| --- | --- | --- |
| `schema_version` | string | Must be `atlas.business_flow_assurance.v1`. |
| `metadata_only` | boolean | Must be `true`. |
| `required` | boolean | Must be `false` at the current maturity stage. |
| `flow` | object | Flow identity, owner, criticality, environment, and scope labels. |
| `operation` | object | Active operation slug and target. |
| `overall` | string | `current`, `attention-required`, `blocked`, or `not-recorded`. |
| `next_step` | string | Operator action to improve the assurance state. |
| `counts` | object | Link counts, open finding count, and validation gap count. |
| `packet` | object | Selected packet name, path, format, verification status, and checks. |
| `checks` | array | Assurance-level checks with status and detail. |
| `known_limitations` | array | Non-goals and limits for this assurance view. |

## Count Fields

`counts` must include:

- `operation_links`
- `evidence_links`
- `finding_links`
- `open_findings`
- `validation_links`
- `validation_gaps`
- `approval_links`
- `retention_links`

`open_findings` is based on the latest linked finding record when available.
`validation_gaps` counts linked findings that do not have a linked validation
record for the same flow and operation.

## Packet Object

`packet` must include:

- `status`: `current`, `stale`, `blocked`, `missing`, or `not-recorded`.
- `format`: `json`, `markdown`, or `none`.
- `packet_name`: selected flow packet slug.
- `path`: selected packet path when applicable.
- `verification_checks`: JSON verifier checks when a JSON packet exists.

## Assurance Checks

Each `checks` item contains:

| Field | Type | Meaning |
| --- | --- | --- |
| `check` | string | Human-readable check name. |
| `status` | string | `ok`, `warning`, `blocked`, or `not-recorded`. |
| `detail` | string | Check-specific detail. |

## Overall Rules

- `not-recorded`: the flow is not linked to the active operation.
- `blocked`: packet verification is blocked.
- `attention-required`: the flow has evidence, finding, validation, retention,
  or packet gaps, open linked findings, or stale packet state.
- `current`: the flow is linked, packet verification is current, linked
  findings have validation coverage, there are no open linked findings, and a
  high- or critical-importance flow has retention coverage.

The command is read-only and should not write ledger events or mutate operation
state.

## Metadata-Only Boundary

This output may include flow labels, operation labels, counts, packet paths,
finding statuses, validation coverage counts, approval and retention counts,
verification statuses, and verifier check metadata.

It must not include raw evidence bodies, finding impact or recommendation
bodies, validation reasons, plan bodies, session contents, approval reasons,
operator notes, retained artifact bodies, request bodies, response bodies,
customer records, payment data, secrets, tokens, credentials, private keys,
session cookies, authorization headers, packet captures, or exploit payloads.

## Non-Goals

- This output is not a retained packet.
- This output does not replace `atlas flow verify`.
- This output does not make Business Flow Evidence required.
- This output does not certify payment delivery, legal compliance, production
  readiness, third-party audit status, or external assurance.
