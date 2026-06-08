# Atlas Master Bible

## Purpose

This is the high-level orientation document for Atlas. It explains Atlas'
mission, proof model, governance stack, business value, operating doctrine,
roadmap direction, and limitations.

Detailed docs, schemas, tests, release evidence, receipts, retained manifests,
and verifier output remain the source of truth. This document is not a
compliance claim, certification, legal opinion, production approval, or external
audit.

## North Star

Atlas exists to make critical digital actions provable without exposing raw
sensitive data.

Trust should come with a receipt.

Privacy is priceless.

Atlas lowers the cost of trust without lowering the standard.

## One-Sentence Definition

Atlas is metadata-first proof infrastructure for critical digital actions.

Atlas records and verifies proof chains around existing systems. It is a trust
overlay, not a replacement for GitHub, Nix, SSH, tmux, scanners, approval tools,
business systems, CI/CD, cloud APIs, AI runtimes, or human reviewers.

Atlas is a trust overlay above existing tools.

## Plain-English Pitch

Important work leaves evidence in too many places: logs, tickets, dashboards,
CI runs, approvals, screenshots, chat, memory, and artifacts. Reviews take
time. Audit evidence is often reconstructed after the fact. Automation and AI
increase action volume, which makes review faster to demand and harder to do
well.

Atlas answers with metadata-only proof receipts, evidence references, artifact
hashes, capability metadata, policy metadata, approval metadata, decision
metadata, replay paths, reviewer-readable summaries, and known limitations.
Atlas helps a reviewer see what happened, what was checked, what remains
unsupported, and how to verify the proof later without turning Atlas into a raw
data warehouse.

## What Atlas Is

Atlas is:

- metadata-first proof infrastructure;
- a local-first trust surface;
- a public reviewer-facing trust surface;
- a proof receipt and replay model;
- a governance contract layer;
- a release trust and evidence retention layer;
- a future open proof infrastructure direction.

## What Atlas Is Not

Atlas is not:

- a scanner;
- a CI/CD replacement;
- a ticketing system;
- a GRC replacement;
- a legal or compliance authority;
- an external auditor;
- a production deployment authority;
- tamper-proof infrastructure;
- immutable storage;
- an autonomous exploitation system;
- a replacement for human judgment.

## Core Philosophy

Atlas favors:

- verifiable integrity over assumed trust;
- metadata-only records before raw-data collection;
- proof before claims;
- boundaries before automation;
- reviewer clarity before product hype;
- local verification before hosted convenience.

Do not make Atlas more impressive by making it less trustworthy.

## Proof-Chain Model

An Atlas proof chain should help answer:

- who requested the action;
- what capability and policy applied;
- whether approval was required;
- what evidence and artifact refs were emitted;
- what commit, packet, or receipt contains the result;
- how another reviewer can verify or replay the proof;
- what the proof does not show.

The point is not to assert trust. The point is to make the trust claim
reviewable, replayable, and bounded by known limitations.

## Metadata-Only Boundary

Atlas proof records must not embed:

- raw logs;
- secrets;
- private keys;
- tokens;
- Authorization headers;
- request bodies;
- response bodies;
- packet captures;
- raw prompts;
- raw model outputs;
- tool output bodies;
- browser/session/cookie material;
- customer data;
- payment data;
- private business records;
- unredacted evidence bodies;
- raw artifacts.

Atlas should use:

- refs;
- hashes;
- IDs;
- statuses;
- timestamps;
- summaries;
- known limitations;
- replay hints;
- reviewer-readable metadata.

## No-Overclaim Boundary

Atlas records and verifies metadata-only proof chains. It does not grant
permission, replace approval authorities, certify compliance, prove legal
sufficiency, guarantee action validity, prove complete event coverage, or
replace human judgment.

Atlas also makes:

- no external audit claim;
- no enterprise deployment approval claim;
- no production certification claim;
- no model correctness proof;
- no artifact correctness guarantee;
- no proof that actions outside Atlas did not happen;
- no runtime safety guarantee;
- no tamper-proof or immutable storage claim.

## Public/Private Repository Boundary

`atlas-trust-infrastructure` is the public reviewer-facing trust surface. It
should contain docs, schemas, public proof examples, retained public evidence,
tests, and reviewer material.

`atlas-lab-toolkit` remains the private implementation and operator runtime
source.

The public repository must not contain private runtime state, target records,
raw evidence, secrets, credentials, host-specific lab details, private operator
notes, vault contents, or private business data.

## Governance Stack

The completed governance stack is:

```text
capability -> adapter -> policy -> approval -> evidence -> integration map -> decision vocabulary
```

| Plane | Purpose | File | Current status | What it does not do |
| --- | --- | --- | --- | --- |
| Capability Manifest | Names and classifies Atlas actions before they are discussed by policy, approval, evidence, or reviewer layers. | `capabilities.yaml` | Draft governance contract with validation. | Does not grant authorization or enforce runtime capability gates by itself. |
| Adapter Registry | Describes external-system and source boundaries before connector behavior exists. | `adapters/registry.yaml` | Draft metadata-only adapter contract with validation. | Does not create live integrations, API calls, webhooks, credentials, or mutation authority. |
| Policy Plane | Models policy decisions, default-deny posture, and evidence/approval expectations. | `policy/policy-plane.yaml` | Draft policy contract with validation. | Does not create a policy engine or runtime policy enforcement. |
| Approval Plane | Models approval states, reviewers, expiration, rejection, escalation, and break-glass documentation. | `approval/approval-plane.yaml` | Draft approval contract with validation. | Does not execute approval workflows or prove action validity. |
| Evidence Envelope | Defines the shared metadata-only proof envelope shape for future emitted records. | `evidence/schemas/evidence-envelope.v1.schema.json` | Draft schema and examples with validation. | Does not collect runtime evidence or preserve raw artifacts. |
| Governance Plane Integration Map | Explains how the governance planes relate from request or imported event to reviewer output. | `docs/governance/GOVERNANCE_PLANE_INTEGRATION_MAP_M182.md` | Architecture documentation. | Does not add runtime orchestration or an action router. |
| Governance Decision Vocabulary | Gives common words to capability, adapter, policy, approval, evidence, reviewer, replay, and system states. | `governance/decision-vocabulary.yaml` | Draft vocabulary with validation. | Does not grant authorization or execute decisions. |

Governance contracts do not imply runtime enforcement. Adapter registry entries
do not imply live integrations. Policy plane docs do not create a policy
engine. Approval plane docs do not create approval workflow execution. Evidence
envelopes are schema contracts unless runtime emission is explicitly
implemented later. Evidence envelopes are schema contracts unless runtime
emission is implemented later. Decision vocabulary terms do not grant
authorization.

Decision vocabulary terms do not grant authorization by themselves.

## Governance Flow

```text
Action request or imported event
  -> capability lookup
  -> adapter/source classification
  -> policy decision model
  -> approval requirement/state
  -> evidence envelope
  -> reviewer output / replay later
```

This is currently an architecture and modeling flow unless runtime execution is
explicitly implemented by a later milestone.

## Decision Vocabulary

Atlas uses common decision terms so reviewers do not have to infer meaning from
different words in different layers. Important terms include:

- `allow`;
- `deny`;
- `approval_required`;
- `evidence_required`;
- `unsupported`;
- `unknown_capability`;
- `unknown_adapter`;
- `boundary_violation`;
- `evidence_missing`;
- `evidence_stale`;
- `evidence_unverifiable`;
- `evidence_outside_atlas`;
- `human_judgment_required`;
- `receipt_verified`;
- `replay_verified`;
- `ready`;
- `blocked`.

`allow` does not grant authorization by itself. `approval_approved` does not
prove action validity. `evidence_sufficient_for_stated_objective` is limited to
the stated objective. `receipt_verified` does not prove external truth.
`replay_verified` does not prove complete event coverage. `ready` does not mean
production certified.

## Reviewer Model

Atlas should help reviewers understand what happened and what remains unknown.
Reviewers need supported and unsupported decisions. Evidence present does not
automatically mean evidence sufficient. Human judgment remains required,
especially for high-risk, ambiguous, stale, unverifiable, outside-Atlas,
business, legal, or approval-dependent decisions.

Plain-English output matters. Reviewer decision packets, evidence sufficiency
reports, reviewer quickstart docs, and replay/verify paths should make the proof
easier to inspect without hiding limitations.

## Release Trust

Release trust remains a critical pillar. Release packets, retained evidence,
signed tags, provenance, QA, release verification, and release replay are part
of Atlas' trust surface.

Release trust does not equal external certification. Local Atlas contract
readiness must remain bounded by the retained evidence, verifier behavior, and
known limitations.

## Business Value

Atlas lowers the cost of trust without lowering the standard.

Atlas can reduce hours spent chasing evidence, lower manual reconstruction
work, make reviews clearer, reduce audit friction, reduce sensitive-data
exposure, and help reviewers understand a decision faster. The value comes from
preserving integrity, approval discipline, known limitations, and human
judgment while making the process easier to verify.

Atlas does not make trust cheaper by weakening the process. Atlas makes trust
cheaper by making the process provable.

The bounded business value is lower cost of trust without lowering standards
and proof without exposure.

## Enterprise Direction, Bounded

Atlas can grow into open proof infrastructure for organizations that need
reviewable, replayable, metadata-only proof of critical digital actions. This
is a product direction, not a current runtime, compliance, certification, or
enterprise-readiness claim.

Future product directions include Atlas Open Core, Atlas Enterprise, Atlas
Verify, Atlas Connectors, Atlas Review, Atlas Policy, and Atlas Evidence Lake.
These remain future directions unless listed as implemented elsewhere in the
repository.

This direction does not claim compliance, certification, external audit
completion, production approval, tamper-proof infrastructure, immutable
storage, complete event coverage, proof that actions outside Atlas did not
happen, runtime safety, model correctness, artifact correctness, or replacement
of human judgment.

- Atlas Open Core: local verifier, receipt schemas, replay, examples, and known
  limitations that preserve local verification.
- Atlas Enterprise: future private trust plane for private collectors, policy
  bundles, approval integrations, audit exports, and organization-specific
  governance while remaining metadata-only.
- Atlas Verify: optional hosted verification convenience; local verification
  should not require hosted verification.
- Atlas Connectors: future import-first, least-privilege integrations that
  reference external systems instead of replacing them.
- Atlas Review: reviewer and auditor clarity workspace for supported decisions,
  unsupported decisions, evidence status, replay paths, and limitations.
- Atlas Policy: capability, approval, and governance modeling before runtime
  enforcement.
- Atlas Evidence Lake: future private metadata index for references, hashes,
  statuses, summaries, and replay hints. Evidence Lake is not source of truth;
  external systems remain their own operational source of truth.

## AI-Agent Governance

AI agents should be requesters, not authorities. Higher-risk AI-agent actions
should be capability-named, policy-aware, approval-aware, and evidence-emitting.

Raw prompts and raw model outputs must not be embedded by default. Atlas does
not prove model correctness or output correctness.

## Recovery / Operating Doctrine

Atlas should stay local-first and verifiable. Retained manifests, vault/recovery
runbooks, workstation snapshots, and self-tests can support local operational
continuity when they remain public-safe and metadata-only.

The public repository must not contain secrets, private vault contents, private
operator notes, private target records, raw logs, raw evidence, or raw runtime
state.

## Milestone Rhythm

Atlas uses a value and safety rhythm:

```text
value -> safety regression -> value -> safety regression
```

The current governance sequence is:

- M172/M173 Capability Manifest;
- M174/M175 Adapter Registry;
- M176/M177 Policy Plane;
- M178/M179 Approval Plane;
- M180/M181 Evidence Envelope;
- M182/M183 Integration Map;
- M184/M185 Decision Vocabulary;
- M186/M187 Public Source Alignment.

## Next Roadmap

Recommended future milestones:

- M189 Atlas Master Bible Safety Regression;
- M190 Enterprise Direction Roadmap Doc;
- M191 Enterprise Direction Roadmap Safety Regression;
- M192 Receipt/Open-Core Schema Alignment;
- M193 Receipt/Open-Core Schema Alignment Safety Regression;
- M194 Governance Demo Packet;
- M195 Governance Demo Packet Safety Regression.

## Known Limitations

- Metadata-only records do not prove external truth.
- Receipts do not prove complete event coverage.
- Replay verifies supplied chain/order only.
- Governance contracts are not runtime engines.
- Validation helpers are not runtime enforcement.
- Approval records do not prove action validity.
- Policy decisions do not prove legal or compliance approval.
- Decision vocabulary does not grant authorization.
- Evidence envelopes are schema contracts unless runtime emission is
  implemented later.
- Atlas does not replace human judgment.

## Final Statement

Atlas should make important work reviewable, replayable, metadata-only,
privacy-preserving, evidence-backed, and honest about its limits.

Trust should come with a receipt.

Proof without exposure.

Lower the cost of trust without lowering the standard.
