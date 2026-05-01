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
| `coverage_model` | string | Must be `aggregate-flow-v1` for the current control coverage model. |
| `flow` | object | Flow identity, owner, criticality, environment, and scope labels. |
| `operation` | object | Active operation slug and target. |
| `overall` | string | `current`, `attention-required`, `blocked`, or `not-recorded`. |
| `next_step` | string | Operator action to improve the assurance state. |
| `counts` | object | Link counts, open finding count, and validation gap count. |
| `controls` | array | Declared control objectives interpreted against aggregate flow evidence state. |
| `link_health` | object | Current reference health for linked evidence, findings, validation, approvals, and retention artifacts. |
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
- `control_objectives`
- `controls_with_aggregate_evidence`
- `controls_with_validation_coverage`

`open_findings` is based on the latest linked finding record when available.
`validation_gaps` counts linked findings that do not have a linked validation
record for the same flow and operation.

## Controls Array

Each `controls` item represents one declared control objective from the flow
record. The current model is aggregate, not per-control evidence mapping.

| Field | Type | Meaning |
| --- | --- | --- |
| `control_objective` | string | Declared flow control objective label. |
| `requirement` | string | `declared`; required/optional control classes are not implemented yet. |
| `coverage_model` | string | `aggregate-flow-v1`. |
| `status` | string | `not-recorded`, `missing-evidence`, `evidence-linked`, `validation-covered`, or `attention-required`. |
| `evidence_links` | number | Aggregate evidence links for the flow. |
| `validation_links` | number | Aggregate validation links for the flow. |
| `finding_links` | number | Aggregate finding links for the flow. |
| `approval_links` | number | Aggregate approval links for the flow. |
| `retention_links` | number | Aggregate retention links for the flow. |
| `open_findings` | number | Current open linked findings for the flow. |
| `validation_gaps` | number | Linked findings without linked validation. |
| `reference_health` | string | Overall link-health state for current linked references. |
| `detail` | string | Human-readable explanation of the aggregate status. |

This version intentionally does not claim that a specific evidence artifact
proves a specific control objective. It reports whether declared controls have
aggregate flow evidence and whether linked findings have validation coverage.

## Link Health Object

`link_health` is a read-only reference integrity summary. It helps reviewers
understand whether current links still resolve before relying on a packet.

It must include:

- `overall`: `ok` or `blocked`.
- `defects`: total malformed, missing, mismatched, or hash-mismatched linked
  references.
- `evidence`: status, link count, malformed link count, missing evidence
  records, missing retained files, hash mismatches, and metadata mismatches.
- `findings`: status, link count, malformed link count, missing finding
  records, and metadata mismatches.
- `validations`: status, link count, malformed link count, missing validation
  records, and metadata mismatches.
- `approvals`: status, link count, malformed link count, missing approval
  records, and metadata mismatches.
- `retention`: status, link count, malformed link count, missing retained
  files, and hash mismatches.

Statuses are metadata-only and do not embed linked artifact bodies. A
nonzero `defects` value makes assurance `blocked` so missing evidence,
finding, validation, approval, or retention references fail clearly.

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
- `blocked`: packet verification is blocked, or link health reports missing,
  malformed, mismatched, or hash-mismatched linked references.
- `attention-required`: the flow has evidence, control objective, finding,
  validation, retention, or packet gaps, open linked findings, or stale packet
  state.
- `current`: the flow is linked, packet verification is current, linked
  findings have validation coverage, declared controls have aggregate evidence,
  there are no open linked findings, and a high- or critical-importance flow
  has retention coverage.

The command is read-only and should not write ledger events or mutate operation
state.

## Metadata-Only Boundary

This output may include flow labels, operation labels, declared control
objective labels, counts, packet paths, finding statuses, validation coverage
counts, approval and retention counts, verification statuses, and verifier
check metadata.

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
