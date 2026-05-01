# `atlas.business_flow_trust_chain.v1`

## Surface

```bash
atlas flow trust-chain --json <flow> [packet-name]
```

## Purpose

Report the trust state for one optional Business Flow Evidence record inside
the active operation. The output is read-only and metadata-only.

## Required Fields

- `schema_version`: must be `atlas.business_flow_trust_chain.v1`.
- `flow.flow_id`
- `flow.flow_slug`
- `flow.flow_name`
- `flow.flow_type`
- `flow.owner`
- `flow.criticality`
- `flow.environment`
- `flow.scope_status`
- `flow.systems`
- `flow.data_classes`
- `flow.control_objectives`
- `operation.slug`
- `operation.target`
- `status`: `not-recorded`, `linked`, `current`, or `attention-required`.
- `next_step`: operator action to make the flow current.
- `required`: must be `false` at the current maturity stage.
- `metadata_only`: must be `true`.
- `links`: counts for operation, evidence, finding, validation, approval, and
  retention links, plus open findings, validation gaps, and control coverage
  counts.
- `link_health`: current reference health for linked evidence, findings,
  validation, approvals, and retention artifacts.
- `review_summary`: compact counts for systems, data classes, controls,
  control coverage, and reference defects.
- `artifacts`: paths to flow link files and packet paths.
- `packets`: Markdown and JSON packet path/existence state.
- `verification`: current verification status, packet format, packet path, and
  JSON verification checks when a JSON packet exists.

## Status Rules

- `not-recorded`: the flow is not linked to the active operation.
- `linked`: the flow has operation context but no verified packet yet.
- `current`: the selected flow packet verifies cleanly.
- `attention-required`: packet verification is stale or blocked, or link
  health reports missing, malformed, mismatched, or hash-mismatched linked
  references.

## Link Health

`link_health` mirrors the assurance view's reference integrity summary. It is
read-only and metadata-only. It reports whether linked evidence, finding,
validation, approval, and retention references still resolve, whether retained
files still exist, and whether hashes still match.

`review_summary.reference_health` must be `ok` or `blocked`.
`review_summary.reference_defects` must count malformed, missing, mismatched,
or hash-mismatched linked references.

## Verification Rules

When a JSON flow packet exists, `atlas flow trust-chain --json` reuses
`atlas flow verify --json` and reports the verifier's overall state and checks.
When only a Markdown packet exists, the text verifier is used and the output
reports the overall verification state without embedding the verifier table.

The command must not write ledger events or mutate operation state.

## Metadata-Only Boundary

This output may include flow identifiers, operation labels, counts, artifact
paths, verification statuses, and verifier check metadata. It must not embed
raw evidence bodies, retained artifact bodies, customer records, request or
response bodies, approval reasons, operator notes, tokens, credentials, private
keys, session cookies, authorization headers, or packet captures.

## Non-Goals

- This output is not a retained packet.
- This output does not replace `atlas flow verify`.
- This output does not make Business Flow Evidence a required pillar.
- This output is not legal, compliance, or external audit certification.
