# Governance Plane Integration Map M182

## Purpose

M182 maps how the drafted Atlas governance planes relate to each other:

- Capability Manifest
- Adapter Registry
- Policy Plane
- Approval Plane
- Evidence Envelope

This is architecture documentation, not runtime orchestration. M182 does not
add an action router, runtime policy enforcement, approval workflow execution,
runtime evidence collection, adapter execution, live integrations, credentials,
API calls, webhooks, network collectors, database, server, or web UI.

## One-Sentence Model

Capability names the action; adapter describes the source/system boundary; policy models the decision; approval models human review; evidence envelope records the proof metadata.

## End-To-End Flow

```text
Action request or imported event
  -> capability lookup
  -> adapter/source classification
  -> policy decision model
  -> approval requirement/state
  -> evidence envelope
  -> reviewer output / replay later
```

The flow is a contract map for contributors and reviewers. It does not execute
the flow at runtime.

## Plane Responsibility Table

| Plane | File(s) | Responsibility | Current status | Future runtime role | What it does not do |
| --- | --- | --- | --- | --- | --- |
| Capability Manifest | `capabilities.yaml` | Names recognized actions, classes, effects, approvals, and evidence expectations. | Draft contract plus safety regression from M172/M173. | Future action classification and capability lookup. | Does not grant authorization, execute actions, or prove the action was valid. |
| Adapter Registry | `adapters/registry.yaml` | Describes external-system/source boundaries, adapter modes, capabilities, evidence, and forbidden inputs. | Draft non-live registry plus safety regression from M174/M175. | Future adapter/source classification and least-privilege connector contract. | Does not add live integrations, API calls, webhooks, network collectors, credentials, or mutation authority. |
| Policy Plane | `policy/policy-plane.yaml` | Models decision inputs, default-deny behavior, decision vocabulary, and policy bundle expectations. | Draft non-enforcing policy contract plus safety regression from M176/M177. | Future policy evaluator input/output contract. | Does not add runtime policy enforcement and policy decisions do not grant authorization by themselves. |
| Approval Plane | `approval/approval-plane.yaml` | Models approval states, reviewer workflows, expiration, reapproval, rejection, escalation, and break-glass documentation boundaries. | Draft non-executing approval contract plus safety regression from M178/M179. | Future approval workflow and reviewer-state contract. | Does not execute approval workflows, add automatic approval, or prove action validity. |
| Evidence Envelope | `evidence/schemas/evidence-envelope.v1.schema.json` | Defines the shared metadata-only record shape for capability, adapter, policy, approval, artifact, hash, review, privacy, and limitation metadata. | Draft schema/examples plus safety regression from M180/M181. | Future evidence emission contract and reviewer-readable proof envelope. | Does not add runtime evidence collection, automatic evidence capture, receipt semantic changes, hashing changes, canonicalization changes, or replay behavior changes. |

## Current Modeled State

M172-M181 define contracts, schemas, examples, validation checks, and safety
regressions. They model how governance metadata should be shaped before Atlas
adds runtime governance.

The current modeled state is useful because it makes the future runtime safer
by making boundaries explicit first. Contributors can see which plane owns a
decision, which fields are expected, which evidence must be emitted, and which
claims remain outside Atlas.

M172-M181 do not yet execute runtime governance. They do not route actions,
enforce policy, execute approvals, collect evidence, or call external systems.

## Future Runtime State

Future work may add runtime components only after the contracts remain stable
and safety regressions protect the boundaries. Possible future layers include:

- action/router later
- policy evaluator later
- approval workflow engine later
- evidence emission later
- private collector/evidence lake later
- hosted verifier later

Those future layers must remain capability-named, adapter-aware, policy-aware,
approval-aware when needed, evidence-emitting, metadata-only, replay-friendly,
and reviewer-readable.

M182 does not implement those future layers.

## Human Review Boundary

Human judgment remains required for high-risk decisions. Atlas can organize
proof metadata and make review cheaper, but it does not replace human review.

Approval records do not prove action validity. Approval records support review
within a declared capability, policy, evidence, and scope boundary.

Policy decisions do not grant authorization by themselves. A modeled decision
is evidence for review, not a runtime authority grant.

Evidence envelopes do not replace reviewer judgment. They record what Atlas
observed, referenced, and limited so another reviewer can inspect and replay the
proof chain later.

## Metadata-Only Boundary

The integration map preserves metadata-only proof. Governance records may store:

- references
- hashes
- IDs
- statuses
- limitations
- replay hints
- reviewer summaries

Governance records must not embed:

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

Atlas proves process metadata without becoming the raw-data warehouse.

## Example Scenario: AI-Agent Action

An AI agent requests tool execution. The capability manifest classifies the
requested action and its risk/effect class. The adapter registry identifies the
source/runtime boundary for the agent event and keeps the event metadata-only.
The policy plane can model `approval_required`, `deny`, or `unsupported` based
on the capability, adapter, scope, risk, and evidence references. The approval
plane records `requested`, `approved`, `rejected`, `expired`, or another bounded
state without executing the tool.

The evidence envelope records metadata-only proof: actor ID, capability ID,
adapter ID, policy decision, approval state, evidence refs, artifact refs,
hashes, privacy exclusions, and known limitations. A reviewer sees what
happened, what was requested, what remains unknown, and what still requires
human judgment.

The agent is requester, not authority. The scenario does not store raw prompts, raw model outputs, or tool output bodies.

## Example Scenario: Release Verification

A release verify action is read-only. The capability manifest identifies release
verification as a read/verify action. The adapter/source boundary points to
GitHub metadata, local artifact refs, retained release packets, provenance refs,
or attestation refs without downloading or embedding raw artifacts. The policy
plane verifies that the read-only action is known and allowed by the modeled
contract. Approval may be `not_required` unless an exception or higher-risk
release decision is being reviewed.

The evidence envelope references artifact hashes, provenance hashes, packet
hashes, commit IDs, and replay hints. A reviewer can replay later through the
local release verify and release replay paths.

No production approval or external certification is implied.

## Example Scenario: Business-Flow Sensitive Change

A business event is imported. The capability manifest classifies the event and
the adapter registry keeps the event import-only. The policy plane checks the
metadata-only boundary and public/private boundary. The approval plane may
require human review for a sensitive change.

The evidence envelope records references, hashes, statuses, evidence
sufficiency state, approval state, reviewer summary, and limitations. No private business records or payment data are embedded. Approval supports review but is not legal/business approval by itself.

## Failure And Boundary States

The integration map keeps boundary and failure states explicit:

- unknown capability
- unknown adapter
- boundary violation
- approval expired
- approval rejected
- evidence missing
- evidence stale
- evidence unverifiable
- evidence outside Atlas
- unsupported decision

These states are review signals. They are not hidden, softened, or converted
into proof of sufficiency.

## What This Enables

The integration map enables:

- clearer review
- lower evidence reconstruction work
- safer future connectors
- privacy-preserving governance
- stronger audit readiness
- lower cost of trust without lowering standards
- proof without exposure

It gives contributors a shared map for adding future governance features without
mixing up contracts, runtime authority, raw data, and reviewer judgment.

## What This Does Not Prove

The integration map does not prove legal compliance.

The integration map does not prove legal sufficiency.

The integration map does not prove production deployability.

The integration map does not prove external audit completion.

The integration map does not prove complete event coverage.

The integration map does not prove actions outside Atlas did not happen.

The integration map does not prove runtime safety.

The integration map does not prove model correctness.

The integration map does not prove artifact correctness.

The integration map does not create tamper-proof infrastructure.

The integration map does not create immutable storage.

The integration map does not replace human judgment.

## Runtime And Implementation Boundaries

M182 adds no runtime orchestration.

M182 adds no action router.

M182 adds no runtime policy enforcement.

M182 adds no approval workflow execution.

M182 adds no runtime evidence collection.

M182 adds no automatic evidence capture.

M182 adds no adapter execution.

M182 adds no live integrations.

M182 adds no credentials/API calls/webhooks/network collectors.

M182 adds no database/server/web UI.

M182 changes no receipt semantics/hashing/canonicalization/replay behavior.

## Future Milestones

- M183 Governance Plane Integration Safety Regression
- M184 Governance Decision Vocabulary
- M185 Governance Decision Vocabulary Safety Regression
- M186 Receipt/Open-Core Schema Alignment
- M187 Receipt/Open-Core Schema Alignment Safety Regression
- M188 Governance Demo Packet
- M189 Governance Demo Packet Safety Regression

## Final Statement

Atlas lowers the cost of trust without lowering the standard.

Atlas proves process metadata without becoming the raw-data warehouse.
