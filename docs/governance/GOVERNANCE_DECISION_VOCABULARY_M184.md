# Governance Decision Vocabulary M184

## Purpose

M184 defines the first shared Atlas governance decision vocabulary in
`governance/decision-vocabulary.yaml`. The vocabulary gives capability,
adapter, policy, approval, evidence, reviewer, and future receipt/open-core
layers the same decision words.

This is a schema and governance contract. It is not runtime decision execution.
It builds on the integration map in
`docs/governance/GOVERNANCE_PLANE_INTEGRATION_MAP_M182.md`.

## Why Atlas Needs A Shared Decision Vocabulary

The governance planes now name actions, source boundaries, policy decisions,
approval states, evidence envelopes, and reviewer outputs. Without a shared
vocabulary, those planes can drift into similar words with different meanings.

M184 lowers that drift risk. It helps reviewers see which decision is being
made, which plane emitted or consumed it, which evidence is expected, which
human judgment remains, and what the decision does not prove.

This supports clearer review, fewer ambiguous decisions, lower evidence
reconstruction work, privacy-preserving governance, stronger audit readiness,
safer future connectors and workflows, lower cost of trust without lowering
standards, and proof without exposure.

The bounded value is clearer review, fewer ambiguous decisions, lower evidence reconstruction work, privacy-preserving governance, stronger audit readiness, safer future connectors and workflows, lower cost of trust without lowering standards, and proof without exposure.

## Vocabulary Is A Schema/Governance Contract, Not Runtime Decision Execution

M184 does not add a runtime decision engine.

M184 does not add runtime orchestration.

M184 does not add action routing.

M184 does not add policy enforcement.

M184 does not add approval workflow execution.

M184 does not add evidence collection.

M184 does not add adapter execution.

M184 does not add live integrations.

M184 does not add credentials, API calls, webhooks, network collectors,
database/server/web UI, or receipt semantic changes.

M184 does not add credentials, API calls, webhooks, network collectors, database/server/web UI, or receipt semantic changes.

M184 changes no hashing/canonicalization/replay behavior.

Decision terms are controlled vocabulary for future records and reviewer
clarity. Decision terms do not grant authorization by themselves.

## Relationship To Capability Manifest

The Capability Manifest in `capabilities.yaml` names recognized actions,
classes, effects, approval posture, and evidence outputs. The decision
vocabulary provides shared words for capability resolution:

- `known_capability`
- `unknown_capability`
- `allow`
- `deny`
- `approval_required`
- `boundary_violation`

`unknown_capability` is not allowed. A known capability still does not grant
authorization by itself.

## Relationship To Adapter Registry

The Adapter Registry in `adapters/registry.yaml` describes source/system
boundaries, modes, capabilities, evidence, and forbidden inputs. The decision
vocabulary provides shared words for adapter resolution:

- `known_adapter`
- `unknown_adapter`
- `adapter_not_live`
- `adapter_import_only`
- `unsupported`
- `boundary_violation`

`unknown_adapter` is not live or allowed. `adapter_not_live` keeps the M174/M175
non-live boundary visible.

## Relationship To Policy Plane

The Policy Plane in `policy/policy-plane.yaml` models policy inputs and
decision outputs before runtime enforcement. M184 aligns policy terms such as:

- `allow`
- `deny`
- `approval_required`
- `evidence_required`
- `unsupported`
- `boundary_violation`

`allow` is a policy modeling term only. It does not grant authorization by
itself, does not imply runtime enforcement, and does not imply legal or
compliance approval.

`deny` preserves default-deny. Unknown, unsupported, or boundary-violating
paths should resolve to safe negative or unsupported states.

## Relationship To Approval Plane

The Approval Plane in `approval/approval-plane.yaml` models approval states and
review workflows before workflow execution. M184 defines shared approval terms:

- `approval_not_required`
- `approval_required`
- `approval_requested`
- `approval_approved`
- `approval_rejected`
- `approval_expired`
- `approval_revoked`
- `approval_stale`
- `approval_escalated`
- `approval_unsupported`

`approval_required` does not execute approval and does not approve anything.
`approval_approved` means an approval state was recorded. It does not prove the
action was valid, does not prove legal sufficiency, does not replace evidence
requirements, and does not execute anything.

## Relationship To Evidence Envelope

The Evidence Envelope schema in
`evidence/schemas/evidence-envelope.v1.schema.json` records metadata-only proof
objects. M184 aligns evidence sufficiency vocabulary:

- `evidence_present`
- `evidence_missing`
- `evidence_stale`
- `evidence_unverifiable`
- `evidence_outside_atlas`
- `evidence_insufficient`
- `evidence_sufficient_for_stated_objective`

`evidence_required` means more evidence is needed before a claim is supported.
It does not mean evidence exists.

`evidence_sufficient_for_stated_objective` means enough evidence is present for
the stated review objective only. It must not imply global sufficiency,
compliance, certification, or complete coverage.

## Relationship To Reviewer Output

Reviewer-facing records should use the same bounded words:

- `review_supported`
- `review_not_supported`
- `human_judgment_required`
- `request_more_evidence`
- `escalate_review`
- `reject_claim`

Human judgment remains explicit for high-risk, ambiguous, unsupported, stale,
or externally dependent decisions. A reviewer decision can be supported by
metadata, but it does not replace reviewer judgment.

## Relationship To Future Receipt/Open-Core Work

Future receipt/open-core alignment should reuse these terms for verification
and replay states:

- `receipt_verified`
- `receipt_not_verified`
- `replay_verified`
- `replay_not_verified`
- `chain_order_unknown`
- `hash_mismatch`

`receipt_verified` means receipt structure and hash checks pass under current
verifier rules. It does not prove external truth or complete event coverage.

`replay_verified` means replay checks pass for the supplied chain and order. It
does not prove no events occurred outside Atlas.

## Decision Categories

M184 defines these decision categories:

| Category | Purpose |
| --- | --- |
| `authorization_model` | Default-deny and authorization-boundary words. |
| `capability_resolution` | Capability lookup and missing-capability words. |
| `adapter_resolution` | Adapter lookup, non-live, and import-only words. |
| `policy_decision` | Policy model outputs before runtime enforcement. |
| `approval_state` | Approval request, decision, expiration, stale, and escalation states. |
| `evidence_sufficiency` | Evidence present, missing, stale, unverifiable, outside Atlas, insufficient, or sufficient for stated objective. |
| `boundary_state` | Unsupported and boundary-violating paths. |
| `reviewer_outcome` | Reviewer-facing support, rejection, escalation, and evidence request words. |
| `replay_state` | Receipt and replay verification words. |
| `system_state` | Local readiness/status words such as ready, warning, blocked, not_ready, stale, and unknown. |

## Required Decision Terms

The required terms are listed in `governance/decision-vocabulary.yaml`.

Authorization and policy terms:

- `allow`
- `deny`
- `approval_required`
- `evidence_required`
- `unsupported`
- `boundary_violation`

Capability and adapter terms:

- `known_capability`
- `unknown_capability`
- `known_adapter`
- `unknown_adapter`
- `adapter_not_live`
- `adapter_import_only`

Approval terms:

- `approval_not_required`
- `approval_requested`
- `approval_approved`
- `approval_rejected`
- `approval_expired`
- `approval_revoked`
- `approval_stale`
- `approval_escalated`
- `approval_unsupported`

Evidence sufficiency terms:

- `evidence_present`
- `evidence_missing`
- `evidence_stale`
- `evidence_unverifiable`
- `evidence_outside_atlas`
- `evidence_insufficient`
- `evidence_sufficient_for_stated_objective`

Reviewer outcome terms:

- `review_supported`
- `review_not_supported`
- `human_judgment_required`
- `request_more_evidence`
- `escalate_review`
- `reject_claim`

Receipt/replay terms:

- `receipt_verified`
- `receipt_not_verified`
- `replay_verified`
- `replay_not_verified`
- `chain_order_unknown`
- `hash_mismatch`

System state terms:

- `ready`
- `warning`
- `blocked`
- `not_ready`
- `stale`
- `unknown`

## Decision Lifecycle

The intended future lifecycle is:

```text
request or imported event
  -> capability resolution
  -> adapter/source resolution
  -> policy decision
  -> approval state when required
  -> evidence sufficiency state
  -> reviewer outcome
  -> receipt/replay state when retained
```

This lifecycle is documentation and vocabulary only in M184. It does not route
actions or execute governance.

## Terminal Vs Non-Terminal Decisions

Terminal decisions stop or close a bounded path, such as `deny`,
`unsupported`, `boundary_violation`, `approval_rejected`, `approval_expired`,
`receipt_not_verified`, `replay_not_verified`, `hash_mismatch`, `blocked`, and
`not_ready`.

Non-terminal or advisory decisions require more context, evidence, approval, or
reviewer judgment, such as `allow`, `approval_required`, `evidence_required`,
`approval_requested`, `approval_stale`, `evidence_missing`,
`evidence_stale`, `evidence_unverifiable`, `evidence_outside_atlas`,
`human_judgment_required`, `request_more_evidence`, `warning`, `stale`, and
`unknown`.

Terminal status in the vocabulary is still metadata-only. It is not runtime
enforcement.

## Human Judgment Boundary

Human judgment remains required where risk, ambiguity, stale state,
unsupported behavior, outside-Atlas evidence, or legal/business interpretation
matters.

Policy decisions do not grant authorization by themselves. Approval records do
not prove action validity. Evidence envelopes do not replace reviewer
judgment. Reviewer outcomes must preserve supported and unsupported decisions.

## Metadata-Only Boundary

Decision vocabulary records may store:

- decision IDs
- categories
- planes
- required context labels
- evidence expectations
- approval expectations
- reviewer visibility
- terminal/advisory flags
- not-proof-of labels
- known limitations

Decision vocabulary records must not store or allow:

- raw logs
- secrets
- private keys
- tokens
- Authorization headers
- request bodies
- response bodies
- packet captures
- raw prompts
- raw model outputs
- tool output bodies
- browser/session/cookie material
- customer data
- payment data
- private business records
- unredacted evidence bodies
- raw artifacts

## What Decision Terms May Record

Decision terms may record references, hashes, IDs, statuses, scope labels,
review objectives, evidence expectations, approval expectations, reviewer
visibility, and limitations.

They may also record whether a decision is terminal, intermediate, or advisory
for reviewer output.

## What Decision Terms Must Not Store

Decision terms must not store raw runtime artifacts, raw evidence bodies,
secret material, session material, prompt or model output bodies, request or
response bodies, packet captures, customer records, payment records, private
business records, or private operator artifacts.

## What Decision Terms Do Not Prove

Decision terms do not prove legal compliance.

Decision terms do not prove legal sufficiency.

Decision terms do not prove production deployability.

Decision terms do not prove external audit completion.

Decision terms do not prove complete event coverage.

Decision terms do not prove actions outside Atlas did not happen.

Decision terms do not prove runtime safety.

Decision terms do not prove model correctness.

Decision terms do not prove artifact correctness.

Decision terms do not create tamper-proof infrastructure.

Decision terms do not create immutable storage.

Decision terms do not replace human judgment.

## Example: AI-Agent Action Decision Path

An AI agent requests tool execution.

1. Capability resolution returns `known_capability` or `unknown_capability`.
2. Adapter/source resolution records `known_adapter`, `adapter_not_live`, or
   `unknown_adapter`.
3. Policy returns `approval_required`, `deny`, `unsupported`, or
   `boundary_violation`.
4. Approval records `approval_requested`, `approval_approved`,
   `approval_rejected`, `approval_expired`, or `approval_stale`.
5. Evidence records `evidence_present`, `evidence_missing`,
   `evidence_unverifiable`, or `evidence_sufficient_for_stated_objective`.
6. Reviewer output may record `human_judgment_required`,
   `request_more_evidence`, `review_supported`, or `reject_claim`.

The agent is requester, not authority. The decision path does not store raw
prompts, raw model outputs, or tool output bodies.

## Example: Release Verification Decision Path

A release verification path is read-only.

1. Capability resolution records release verification as a known capability.
2. Adapter/source resolution points to GitHub or local artifact refs without
   adding live integration.
3. Policy may record `allow`, `evidence_required`, `deny`, or
   `boundary_violation`.
4. Approval is usually `approval_not_required` unless an exception review is
   needed.
5. Evidence records artifact and provenance refs/hashes only.
6. Receipt and replay states may record `receipt_verified` and
   `replay_verified`.

This path does not imply production approval, external certification, artifact
correctness, legal compliance, or complete event coverage.

## Example: Business-Flow Sensitive Change Decision Path

A business-flow sensitive change is imported as metadata.

1. Capability resolution classifies the action.
2. Adapter resolution remains import-only.
3. Policy checks metadata-only and public/private boundaries.
4. Approval may record `approval_required`, `approval_requested`,
   `approval_approved`, `approval_rejected`, `approval_expired`, or
   `approval_stale`.
5. Evidence records references, hashes, statuses, and limitations.
6. Reviewer output may request more evidence or support only the stated review
   objective.

No private business records or payment data are embedded. Approval supports
review but is not legal/business approval by itself.

## Failure And Boundary States

Failure and boundary states must remain explicit:

- `unknown_capability`
- `unknown_adapter`
- `unsupported`
- `boundary_violation`
- `approval_rejected`
- `approval_expired`
- `approval_revoked`
- `approval_stale`
- `evidence_missing`
- `evidence_stale`
- `evidence_unverifiable`
- `evidence_outside_atlas`
- `evidence_insufficient`
- `chain_order_unknown`
- `hash_mismatch`
- `blocked`
- `not_ready`
- `unknown`

These states keep Atlas from turning absence, ambiguity, stale state, or
boundary violations into positive claims.

## Reviewer/Auditor Value

The shared vocabulary makes reviewer output easier to compare across
capability, adapter, policy, approval, evidence, and receipt layers. It reduces
interpretation drift, lowers evidence reconstruction work, keeps unsupported
paths visible, and preserves privacy-preserving governance.

The value is review clarity and audit readiness, not a stronger claim than the
metadata supports.

## Known Limitations

- M184 is a draft/value milestone only.
- M184 defines controlled vocabulary; it does not add runtime behavior.
- The vocabulary does not prove external truth or complete event coverage.
- The vocabulary does not decide legal, compliance, business, or production
  sufficiency.
- Existing external systems remain their own operational source of truth.
- Future runtime work must remain capability-named, adapter-aware,
  policy-aware, approval-aware when needed, evidence-emitting, metadata-only,
  reviewer-readable, and replay-friendly.

## Future Milestones

- M185 Governance Decision Vocabulary Safety Regression
- M186 Receipt/Open-Core Schema Alignment
- M187 Receipt/Open-Core Schema Alignment Safety Regression
- M188 Governance Demo Packet
- M189 Governance Demo Packet Safety Regression
