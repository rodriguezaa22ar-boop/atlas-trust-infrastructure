# Reviewer Plain-English Output M166

## Purpose

Atlas supports plain-English reviewer output by translating proof receipts,
replay results, evidence sufficiency, and reviewer decision packets into a
reader mode for people who do not need every schema, hash, or command detail.

The output helps reviewers answer:

- What happened?
- What evidence exists?
- What evidence is missing, stale, or unverifiable?
- What did Atlas verify?
- What still needs human judgment?
- What decision does this evidence support?
- What decision does this evidence not support?

The value is practical: faster review, less evidence chasing, a clearer
decision path, lower exposure of sensitive data, better audit readiness, and
clearer accountability.

M166 is a documentation format. It does not add runtime behavior, a command, a
database, a server, a web UI, a live integration, a new adapter, or receipt
semantic changes.

## Intended Readers

This reader-mode output is for:

- security reviewers who need a quick evidence summary;
- release managers who need to understand release-review support;
- auditors who need a clear path from claim to evidence;
- engineering leaders who need to see blockers and follow-up actions;
- business stakeholders who need a plain statement of what the evidence
  supports and what remains outside Atlas.

## Plain-English Vocabulary

| Term | Plain-English meaning |
| --- | --- |
| proof receipt | A small evidence record that says what action or event was recorded, who or what produced it, and which hashes bind it to the reviewed record. |
| metadata-only | The receipt stores references and hashes, not raw logs, secrets, prompts, customer data, request bodies, response bodies, or full terminal output. |
| replay | Atlas checked that the receipts link together in the expected order. |
| evidence sufficiency | Atlas shows which evidence is `present`, `missing`, `stale`, or `unverifiable`. |
| local Atlas contract | Atlas' own evidence gates passed for the local review path; this is not the same as external certification. |
| reviewer decision packet | A bounded reviewer summary that connects the objective, evidence status, local checks, known limitations, and the decision that remains with the reviewer or authority. |

Related review docs:

- [../TRUST_CLAIM_LADDER.md](../TRUST_CLAIM_LADDER.md)
- [EVIDENCE_SUFFICIENCY_REPORT_M158.md](EVIDENCE_SUFFICIENCY_REPORT_M158.md)
- [REVIEWER_DECISION_PACKET_M160.md](REVIEWER_DECISION_PACKET_M160.md)
- [../workflows/ORG_CI_RELEASE_REVIEW_WORKFLOW_M164.md](../workflows/ORG_CI_RELEASE_REVIEW_WORKFLOW_M164.md)
- [../KNOWN_LIMITATIONS.md](../KNOWN_LIMITATIONS.md)

## Reader-Mode Output Structure

Use this structure when writing for a mixed technical and non-technical review
audience:

```text
Summary
What happened
What Atlas verified
Evidence found
Evidence missing or needs attention
Decision this supports
Decision this does not support
What still needs human judgment
Next recommended action
Known limitations
```

The goal is to reduce evidence chasing while keeping the decision boundary
visible.

## Example: CI Release Review

### Summary

Atlas reviewed local GitHub Actions run/check metadata for one CI release
candidate. The evidence is metadata-only and tied to the reviewed receipt
chain.

### What happened

An operator imported a workflow run event and a linked check event from local
metadata files. Atlas generated proof receipts for both events.

### What Atlas verified

- Atlas checked that each proof receipt is structurally valid and its hashes
  match.
- Atlas checked that the run and check receipts link together in the expected
  order.
- Atlas checked that the receipts preserve the metadata-only boundary.

### Evidence found

- Workflow run receipt: present.
- Check run receipt: present.
- Linked replay result: present.
- Review objective and reviewed commit: present.

### Evidence missing or needs attention

- Raw CI logs are intentionally not embedded.
- Approval evidence may be missing, stale, or unverifiable.
- Release notes may be missing, stale, or unverifiable.
- Missing events can exist outside the proof chain.

### Decision this supports

This supports proceeding with an internal CI release review when the reviewer
accepts the visible limitations and follows up on missing, stale, or
unverifiable evidence.

### Decision this does not support

This does not support a claim that every CI event was captured, that business
approval happened, that legal sufficiency is established, or that external
assurance is complete.

### What still needs human judgment

A reviewer still decides whether the CI metadata, approvals, release notes,
and process context satisfy the team's release-review objective.

### Next recommended action

Use the
[Organization CI Release Review Workflow M164](../workflows/ORG_CI_RELEASE_REVIEW_WORKFLOW_M164.md)
to record missing evidence, refresh stale evidence, rerun verification, or
escalate the determination outside Atlas.

## Example: AI-Agent Action Review

### Summary

Atlas reviewed metadata-only AI-agent action and result receipts. The review
path treats the AI agent as an event source, not as an authority or execution
engine.

### What happened

An operator imported an AI-agent proposed-action event and a linked result
event through the existing generic external event adapter.

### What Atlas verified

- Atlas checked that the proof receipts are structurally valid and their
  hashes match.
- Atlas checked that the linked receipts replay in the expected order.
- Atlas checked that raw prompts, raw model outputs, raw tool bodies, and
  secret-bearing material are outside the receipt boundary.

### Evidence found

- Proposed-action receipt: present.
- Result receipt: present.
- Linked replay result: present.
- Known limitations: present.

### Evidence missing or needs attention

- Human authorization may be missing, stale, or unverifiable.
- Source-system truth may be outside the packet.
- Tool safety evidence may need separate review.

### Decision this supports

This supports reviewer inspection of what the AI-agent event record says and
whether the local proof envelope verifies.

### Decision this does not support

This does not support treating the AI agent as an approval authority, execution
authority, model-correctness source, or safety authority.

### What still needs human judgment

A human reviewer or policy owner still decides whether the proposed action was
authorized, appropriate, and acceptable for the business process.

### Next recommended action

Use the AI-agent proof package and reviewer decision packet to record whether
approval evidence is present, missing, stale, or unverifiable.

## Example: Production-Readiness Review

### Summary

Atlas reviewed production-readiness evidence under the local Atlas contract.
This means Atlas' local evidence gates are visible and reviewable; it is not
the same as external certification.

### What happened

An operator gathered retained release-trust evidence, production-readiness
mapping, evidence sufficiency status, and reviewer decision packet context for
one reviewed commit.

### What Atlas verified

- Atlas checked local release-trust evidence paths.
- Atlas checked whether required evidence can be classified as present,
  missing, stale, or unverifiable.
- Atlas checked public export and reviewer package paths when those commands
  are run.

### Evidence found

- Reviewed commit: present.
- Release-trust references: present when retained and verified.
- Production-readiness control mapping: present.
- Evidence sufficiency report shape: present.

### Evidence missing or needs attention

- Signing or provenance evidence may be missing, stale, or unverifiable.
- Production dry-run evidence may be missing, stale, or unverifiable.
- Reviewer package evidence may need regeneration if the reviewed state
  changed.

### Decision this supports

This supports production-readiness review under the local Atlas contract when
required evidence is present and the reviewer accepts known limitations.

### Decision this does not support

This does not support deployment approval outside the local Atlas contract,
external certification, legal conclusion, source-system truth, or artifact
correctness.

### What still needs human judgment

Reviewers, approvers, auditors, or authorities still decide signer authority,
deployment approval, residual risk, audit outcome, and business acceptance.

### Next recommended action

Use the evidence sufficiency report to refresh stale evidence, remediate
missing evidence, investigate unverifiable evidence, or escalate the decision.

## What Atlas Checked

Plain-English output should translate technical checks like this:

- `receipt verify` means Atlas checked that the proof receipt is structurally
  valid and its hashes match.
- `receipt replay` means Atlas checked that the receipts link together in the
  expected order.
- `metadata-only` means the receipt stores references and hashes, not raw logs,
  secrets, prompts, customer data, request bodies, response bodies, or full
  terminal output.
- `evidence sufficiency` means Atlas shows which evidence is present, missing,
  stale, or unverifiable.
- `local Atlas contract` means Atlas' own evidence gates passed for the local
  review path; this is not the same as external certification.

## What Evidence Exists

Reader-mode output should list evidence in direct language:

- receipt exists and verifies;
- linked receipt replay exists and passes;
- reviewed commit is named;
- evidence sufficiency status is recorded;
- known limitations are present;
- reviewer follow-up is named.

## What Is Missing, Stale, Or Unverifiable

Reader-mode output should not hide gaps:

- `missing` means required evidence is absent or not referenced.
- `stale` means evidence exists but may no longer represent the reviewed
  state.
- `unverifiable` means evidence exists but Atlas cannot verify it locally.

These statuses support faster review and less evidence chasing because the
reviewer can see which issue needs attention.

## What Decision The Evidence Supports

Evidence can support decisions such as:

- proceed with internal review;
- request missing evidence;
- rerun verification;
- refresh stale retained evidence;
- escalate to a reviewer, auditor, approver, or authority.

The support is bounded by the evidence that is present and verified.

## What Decision The Evidence Does Not Support

Atlas evidence does not decide:

- external certification;
- legal or compliance conclusions;
- deployment approval outside the local Atlas contract;
- model correctness;
- runtime safety;
- artifact correctness;
- complete event coverage;
- whether no action happened outside Atlas.

Those determinations remain with the reviewer, approver, auditor, authority, or
other outside process.

## Human Judgment Still Required

Human judgment remains required for:

- business approval;
- policy acceptance;
- authorization and authority;
- source-system truth;
- missing-event risk;
- residual risk;
- whether limitations are acceptable.

Atlas makes the proof envelope easier to inspect. It does not replace the
reviewer.

## Known Limitations

- M166 is docs/tests only.
- M166 does not add a reader-mode command or output schema.
- M166 does not change receipt verification, replay, adapters, release
  verification, reviewer packages, public export, or production status gates.
- Plain-English output summarizes metadata-only evidence; it must not embed raw
  logs, secrets, prompts, customer data, packet captures, request bodies,
  response bodies, or full terminal dumps.
- Known limitations remain part of the output because they tell reviewers what
  the evidence can and cannot support.

## Reviewer Checklist

- Confirm the summary names the reviewed event, release, action, or objective.
- Confirm "What happened" is understandable without reading JSON.
- Confirm "What Atlas verified" states local checks in plain English.
- Confirm "Evidence found" separates present evidence from assumptions.
- Confirm missing, stale, or unverifiable evidence is visible.
- Confirm the supported decision is bounded by the evidence.
- Confirm unsupported decisions are explicit.
- Confirm human judgment and outside determinations remain visible.
- Confirm raw logs, secrets, prompts, customer data, request bodies, response
  bodies, and full terminal output are not embedded.
