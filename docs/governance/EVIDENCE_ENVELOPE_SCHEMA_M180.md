# Evidence Envelope Schema Draft M180

## Purpose

M180 defines the first Atlas evidence-envelope schema draft. The envelope is
the shared metadata-only record shape that future capability, adapter, policy,
approval, workflow, and receipt decisions can emit for review and replay.

The draft schema lives at
`evidence/schemas/evidence-envelope.v1.schema.json`. Draft examples live under
`evidence/examples/evidence-envelope/`.

## Why Atlas Needs An Evidence Envelope

Atlas already has capability, adapter, policy, and approval governance-plane
contracts. Reviewers still need one consistent evidence shape that connects
those decisions to evidence references, artifact hashes, known limitations,
privacy boundaries, and replay hints.

The evidence envelope supports:

- clearer review
- fewer ambiguous evidence records
- lower evidence reconstruction work
- privacy-preserving proof
- stronger audit readiness
- lower cost of trust without lowering standards
- proof without exposure

## Schema Contract, Not Runtime Collection

The evidence envelope is a schema contract, not runtime collection. M180 does
not add runtime evidence collection. M180 does not add automatic evidence
capture. M180 does not add a database, evidence lake, server, web UI, live
integration, adapter execution, policy enforcement, or approval execution.

M180/M181 do not add runtime evidence collection.
M180/M181 do not add automatic evidence capture.
M180/M181 do not add an evidence collector.
M180/M181 do not add database/server/web UI.
M180/M181 do not add an evidence lake implementation.
M180/M181 do not add live integrations.
M180/M181 do not add credentials.
M180/M181 do not add API calls.
M180/M181 do not add webhooks.
M180/M181 do not add network collectors.
M180/M181 do not add adapter execution.
M180/M181 do not add policy enforcement.
M180/M181 do not add approval execution.
M180/M181 do not change receipt semantics.
M180/M181 do not change hashing behavior.
M180/M181 do not change canonicalization behavior.
M180/M181 do not change replay behavior.
`bin/dev-evidence` is validation tooling only.

M180 does not change receipt semantics, hashing, canonicalization, or replay behavior.
M180 defines a draft metadata-only envelope schema for future evidence records.

Future evidence emission must remain capability-named, adapter-aware,
policy-aware, approval-aware when needed, metadata-only, and reviewer-readable.
Existing external systems remain the source of their own operational truth.
Atlas records proof metadata around them.
The envelope preserves metadata-only integration with capability, adapter,
policy, approval, workflow, and receipt proof records.

## Relationship To `capabilities.yaml`

The `capability` section links an envelope to a capability ID, class, known
state, and status. This helps reviewers see which named capability the evidence
supports without granting authorization or executing the capability.

## Relationship To `adapters/registry.yaml`

The `adapter` section links an envelope to an adapter ID, mode, known state,
live-integration flag, and source system. Adapter-bound envelopes must preserve
the M174/M175 rule that draft adapters are non-live and metadata-only.

## Relationship To `policy/policy-plane.yaml`

The `policy` section records modeled decisions, bundle references, reason
references, boundary violations, and `runtime_enforcement: false`. Policy
metadata helps reviewers understand the decision context without implying
active policy enforcement.

## Relationship To `approval/approval-plane.yaml`

The `approval` section records approval state, workflow ID, whether approval
was required, approver references, decision reference, expiration, and
reapproval status. Approval metadata does not execute approval workflows and
does not grant authorization by itself.

## Envelope Types

The draft vocabulary is:

- `decision`
- `adapter_event`
- `approval_event`
- `run_event`
- `receipt_event`
- `release_verify`
- `business_flow_event`
- `ai_agent_action`
- `checkpoint`

These types describe metadata records. They do not make Atlas a runtime
evidence collector.

## Required Top-Level Fields

Every M180 envelope has:

- `schema_version`
- `envelope_id`
- `envelope_type`
- `created_at`
- `producer`
- `actor`
- `subject`
- `action`
- `capability`
- `adapter`
- `policy`
- `approval`
- `evidence`
- `artifacts`
- `hashes`
- `review`
- `privacy`
- `known_limitations`

The schema requires `schema_version: atlas.evidence_envelope.v1`.

## Metadata-Only Evidence References

The `evidence` section records references, sufficiency status, missing
evidence, stale evidence, unverifiable evidence, and evidence outside Atlas.
Evidence references are refs, hashes, statuses, or pointers to retained
metadata. They are not raw evidence bodies.

## Artifact References And Hash Fields

The `artifacts` section records artifact refs, artifact hashes, and source
refs. It must not embed raw artifacts. The `hashes` section can record
`event_hash`, `prev_hash`, `receipt_hash`, `content_hash`, and `chain_head`.
M180 defines these fields only; it does not implement hashing or
canonicalization changes.

Hash fields are metadata fields in the draft schema.
M180/M181 do not implement hashing.
M180/M181 do not implement signing.
M180/M181 do not implement immutable storage.
M180/M181 do not implement tamper-proof infrastructure.
Atlas distinguishes tamper-evidence from tamper-proof claims.
Content hashes do not prove external truth by themselves.
Chain hints do not prove complete event coverage.

## Review And Replay Hints

The `review` section records a reviewer summary, supported decision,
unsupported decisions, whether human judgment is required, and a replay hint.
Replay hints are reviewer instructions or verifier references. They do not
prove external truth by themselves.

Review hints are guidance for reviewers.
Replay hints are not proof by themselves.
Reviewer summaries must preserve known limitations.
Supported decisions and unsupported decisions must both be represented.
Unsupported decisions should remain explicit.
Human judgment required language must remain visible when the envelope cannot
support a decision by itself.

## Privacy Boundary

The `privacy` section must default to:

- `metadata_only: true`
- `raw_artifacts_embedded: false`
- `forbidden_content_excluded: true`

The privacy section also records whether redaction is required and which
sensitive data classes were excluded.

## What Evidence Envelopes May Store

Evidence envelopes may store:

- actor, producer, subject, action, capability, adapter, policy, and approval
  metadata
- evidence references and evidence sufficiency states
- artifact references and SHA-256-style hash references
- event, previous, receipt, content, and chain-head hash fields
- reviewer summaries, unsupported decisions, and replay hints
- privacy flags and known limitations

## What Evidence Envelopes Must Not Store

Evidence envelopes must not store raw logs, secrets, private keys, tokens,
Authorization headers, request bodies, response bodies, packet captures, raw
prompts, raw model outputs, customer data, payment data, private business
records, unredacted evidence bodies, raw artifacts, full tool output bodies,
browser session material, or session cookies by default.

## Evidence Sufficiency States

The draft evidence section supports:

- `present`
- `missing`
- `stale`
- `unverifiable`
- `outside_atlas`
- `not_evaluated`

Evidence present does not automatically mean evidence sufficient. Missing,
stale, unverifiable, or outside-Atlas evidence should remain visible so a
reviewer can decide what the envelope supports and what it does not support.

## AI-Agent Action Envelope Boundary

AI-agent envelopes treat agents as requesters, not authorities. They may record
metadata references for a requested action, scope review, policy decision, and
approval state. They must not embed raw prompts or raw model outputs, and they
do not prove model correctness or authorize tool execution.

## Release Verification Envelope Boundary

Release verification envelopes describe read-only verification metadata:
release packet references, provenance references, attestation references,
artifact hashes, verification status, and replay hints. They do not guarantee
artifact correctness, certify production readiness, or mutate release systems.

## Business-Flow Envelope Boundary

Business-flow envelopes are metadata-only and referential. They may record
business-flow IDs, owner labels, control objectives, evidence refs, approval
state, and known limitations. They must not embed private business data,
payment data, customer data, or unredacted business records.

## What Evidence Envelopes Do Not Prove

Evidence envelopes do not grant authorization.
Evidence envelopes do not prove the action was valid.
Evidence envelopes do not prove action validity.
Evidence envelopes do not prove legal compliance.
Evidence envelopes do not prove legal sufficiency.
Evidence envelopes do not prove production deployability.
Evidence envelopes do not prove enterprise deployment approval.
Evidence envelopes do not prove complete event coverage.
Evidence envelopes do not prove actions outside Atlas did not happen.
Evidence envelopes do not replace human judgment.

Evidence envelopes also do not prove runtime safety, model correctness,
artifact correctness, external audit completion, enterprise deployment
approval, legal sufficiency, tamper-proof infrastructure, or immutable storage.

## Known Limitations

- M180 is a draft schema and example set only.
- M180 does not add runtime evidence collection.
- M180 does not add automatic evidence capture.
- M180 does not add an evidence lake implementation.
- M180 does not add live integrations, credentials, API calls, webhooks,
  network collectors, or mutation.
- M180 does not add adapter execution.
- M180 does not add policy enforcement.
- M180 does not add approval execution.
- M180 does not change receipt semantics, hashing, canonicalization, or replay behavior.
- M180 does not preserve raw artifacts.
- M180 does not create a production evidence system.

## Future Milestones

Future milestones may define:

- evidence envelope safety regression
- receipt-to-envelope mapping
- batch evidence envelope validation
- policy decision envelope emission
- approval event envelope emission
- adapter import envelope emission
- reviewer evidence-envelope summary
- evidence-envelope replay report
- private collector evidence-envelope export contract
- hosted verifier evidence-envelope boundary
