# External Project Receipt Reviewer Output Example

## Receipt

- Receipt ID: `receipt_generic_external_event_v1_m190-external-project-minimal-event`
- Action: `external_project.action.reviewed`
- Verification status: `ok`
- Event hash: `0c3a8f3ec6e2e8a029e4fd9e0f7a3a694ab5d725025c58203cc048afabee3f11`
- Receipt hash: `cd619c4954af802b66a76e0dd379a01973e19458003dd163019d867cdc3797d3`

## What Atlas verified

Atlas verified the local receipt metadata contract for the receipt file it was
given:

- schema: `atlas.receipt.v1`
- metadata_only=true
- raw_artifacts_embedded=false
- evidence references: 12
- artifact references: 1
- approval references: 1
- replay posture: genesis receipt unless a later receipt supplies this event hash
  as `prev_hash`

## Reviewer-visible references

- Project: `external_project://project/synthetic-payments-demo`
- System: `external_project://system/change-management-demo`
- Capability: `external_project://capability/external.change.review`
- Policy: `external_project://policy/change-policy-demo-v1`
- Approval: `approval:synthetic-change-001`
- Input digest reference: `sha256:input:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa`
- Output digest reference: `sha256:output:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb`

## What Atlas did not verify

Atlas did not verify source-system truth, external artifact availability, action
correctness, artifact correctness, model correctness, legal compliance,
production approval, external audit completion, complete event coverage,
tamper-proof storage, immutable infrastructure, or replacement of human
judgment.

## Decision outside Atlas

The reviewer must decide whether the referenced project, system, policy,
approval, evidence, artifact, input hash, output hash, and known limitations are
sufficient for the specific review. Atlas provides a metadata-only proof aid; it
is not the approval authority.

## Boundary

This example is synthetic and metadata-only. It does not contain raw logs, raw
prompts, raw model outputs, terminal buffers, request bodies, response bodies,
packet captures, credentials, tokens, private keys, session cookies, customer
data, payment data, private business records, private target records, or
unredacted evidence bodies.
