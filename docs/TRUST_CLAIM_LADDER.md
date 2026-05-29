# Atlas Trust Claim Ladder

Atlas supports stronger review outcomes by turning hardened proof primitives
into replayable, metadata-only evidence. Receipts, adapters, proof packages,
and reviewer workflows become useful when a reviewer can see what evidence is
present, what Atlas verified, and which determination remains outside Atlas.

Atlas is not shrinking into disclaimers.

Boundaries are criteria for stronger claims. Every stronger claim requires
evidence, and Atlas verifies the proof envelope before a reviewer, auditor,
approver, or authority records the final determination.

Every stronger claim requires evidence.

Atlas maps receipts, adapters, proof packages, and reviewer workflows to
positive review outcomes.

## Purpose

M154 defines the first positive claim architecture for Atlas. The ladder
translates receipts, adapter imports, replay checks, proof packages, retained
release evidence, approvals, and business-flow records into review objectives
that can be inspected without adding runtime behavior.

The ladder answers:

- what Atlas supports;
- what evidence the support claim requires;
- what Atlas verifies locally;
- what remains for reviewers, auditors, approvers, or authorities.

## Claim Ladder

| Level | Positive claim level | What Atlas supports | Evidence required | What Atlas verifies | Outside-Atlas determination |
| --- | --- | --- | --- | --- | --- |
| Level 0 | Receipt integrity | A receipt can be checked as a local, metadata-only proof record. | `atlas.receipt.v1` JSON, `metadata_only=true`, `raw_artifacts_embedded=false`, evidence refs, artifact refs, known limitations. | Receipt structure, required fields, canonical `event_hash`, canonical `receipt_hash`, metadata-only boundary, forbidden-marker absence, and known limitations. | Whether the receipt subject accurately represents the external action or business event. |
| Level 1 | Replayable action record | Linked receipts can preserve an ordered action record for review. | Ordered receipt files, each receipt's `event_hash`, each later receipt's `prev_hash`, replay command output. | Each receipt verifies and replay order satisfies `prev_hash -> event_hash`. | Whether the caller-provided order is the authoritative chronology for the review objective. |
| Level 2 | Review-ready event package | AI-agent, CI, release, approval, or business events can be packaged for reviewer inspection. | Local event JSON, proof package docs, examples, verifier commands, expected output shape, known limitations. | Event package is local-file, metadata-only, import-only when imported, and replayable when receipts are linked. | Whether the event package is sufficient for the reviewer question or needs source-system follow-up. |
| Level 3 | Control-objective support | Receipts can be mapped to AI-agent governance, CI integrity, release governance, approval integrity, audit readiness, and business workflow assurance. | Control objective mapping, receipt chains, proof packages, approval refs, release refs, business-flow refs, retained milestones. | The proof envelope contains the evidence refs and verification outputs needed to support the stated objective. | Whether the supported evidence satisfies the internal control, audit criterion, policy, or rule of engagement. |
| Level 4 | Evidence sufficiency support | Atlas can report evidence as present, missing, stale, malformed, dirty, unsynced, or unverifiable. | Status outputs, verifier outputs, replay outputs, trust-chain checks, release checks, public export checks, known limitations. | Local evidence state and failure mode are visible enough for follow-up without embedding raw evidence. | Whether missing or stale evidence blocks the review, requires remediation, or can be accepted as residual risk. |
| Level 5 | External assurance support | Atlas can support external audit, compliance, security, or release review with reproducible local evidence. | Reviewer package, retained release evidence, public export manifest, proof packages, signed or attributed reviewer conclusions when available. | The local package is bounded, metadata-only, hash-checkable, and replayable with documented limits. | External audit completion, legal compliance, certification, deployment approval, risk acceptance, and final assurance conclusions. |

## What Atlas Supports

Atlas supports positive review claims when the evidence can be replayed or
verified:

- receipt integrity through deterministic receipt hashes;
- replayable action records through linked receipt chains;
- AI-agent action governance through metadata-only event-source receipts;
- GitHub Actions / CI integrity through local-file run/check metadata receipts;
- release governance through release packet, manifest, replay, and retained
  provenance references;
- approval integrity through approval refs and approval event metadata;
- audit readiness through reviewer packages, public export checks, retained
  milestones, and known limitations;
- business workflow assurance through metadata-only business-flow records,
  packets, assurance status, and trust-chain summaries.

## Evidence Required

Every stronger claim requires evidence. Useful Atlas evidence is:

- metadata-only by default;
- explicit about known limitations;
- referential instead of embedding raw logs, raw prompts, raw model output,
  packet captures, request bodies, response bodies, credentials, tokens,
  private keys, or sensitive business records;
- replayable or verifiable through a local command;
- tied to a reviewed commit, retained milestone, proof package, receipt chain,
  release packet, approval record, or business-flow packet;
- clear about whether evidence is present, missing, stale, malformed, dirty,
  unsynced, or unverifiable.

## What Atlas Verifies

Atlas verifies the proof envelope:

- JSON structure and required metadata fields;
- `metadata_only=true`;
- `raw_artifacts_embedded=false`;
- forbidden raw-content and secret-shaped marker absence;
- deterministic receipt canonicalization and SHA-256 hash recomputation;
- linked replay order through `prev_hash -> event_hash`;
- local adapter import boundaries for `generic.external_event.v1`;
- local release packet, release manifest, reviewer package, public export, and
  business-flow packet checks when those commands are run;
- known limitations remain visible.

## What Remains For Reviewers Auditors Authorities

Reviewers, auditors, approvers, and authorities make determinations that Atlas
can support with evidence but cannot grant by itself:

- source-system truth;
- source-system availability;
- approval sufficiency;
- authorization;
- legal or contractual adequacy;
- artifact correctness;
- model correctness;
- tool safety;
- production deployment readiness;
- external audit completion;
- compliance conclusion;
- certification result;
- residual risk acceptance.

## Control Objective Coverage

| Objective | Positive support claim | Primary evidence | Verification path |
| --- | --- | --- | --- |
| AI-agent action governance | Atlas supports review of AI-agent proposed actions and reported results as event-source metadata. | AI-agent profile, action/result examples, M148 security regression, M150 proof package. | `atlas receipt import-generic-event`, `atlas receipt verify`, `atlas receipt replay`. |
| GitHub Actions / CI integrity | Atlas supports review of CI run/check metadata without calling GitHub or embedding raw logs. | M151 examples, M152 security regression, M153 proof package. | Import run/check events, verify receipts, replay linked run/check chain. |
| release governance | Atlas supports review of retained release evidence and replayable release-trust state. | Release packet, release manifest, signed tag refs, retained provenance refs, known limitations. | `atlas release verify`, `atlas release manifest-verify`, `atlas release replay`. |
| approval integrity | Atlas supports review of approval evidence linked to governed actions. | Approval events, policy refs, receipt `approval_refs`, expiry and rationale metadata. | `atlas approval verify`, policy evaluation, receipt verify, receipt replay. |
| audit readiness | Atlas supports cloneable review of bounded public trust evidence. | Reviewer package, public export manifest, proof packages, retained milestones. | `atlas reviewer package`, `bin/export-public-trust --check`, receipt/release verification. |
| business workflow assurance | Atlas supports review of business-flow evidence links without embedding sensitive business data. | Business-flow records, evidence/finding/validation/approval/retention links, flow packets, assurance status. | `atlas flow packet`, `atlas flow verify`, `atlas flow assurance`, `atlas op trust-chain`. |

The detailed mapping lives in
[reviews/CONTROL_OBJECTIVE_MAPPING.md](reviews/CONTROL_OBJECTIVE_MAPPING.md).

## Reference Paths

- [RECEIPTS.md](RECEIPTS.md): receipt structure, verification, replay, and
  canonicalization boundaries.
- [adapters/GENERIC_EXTERNAL_EVENT_RECEIPT_ADAPTER.md](adapters/GENERIC_EXTERNAL_EVENT_RECEIPT_ADAPTER.md):
  `generic.external_event.v1` local-file import boundary.
- [adapters/AI_AGENT_EVENT_RECEIPT_PROFILE.md](adapters/AI_AGENT_EVENT_RECEIPT_PROFILE.md):
  metadata-only AI-agent event profile.
- [reviews/AI_AGENT_EVENT_PROOF_PACKAGE_M150.md](reviews/AI_AGENT_EVENT_PROOF_PACKAGE_M150.md):
  AI-agent event proof package.
- [reviews/GITHUB_ACTIONS_EVENT_PROOF_PACKAGE_M153.md](reviews/GITHUB_ACTIONS_EVENT_PROOF_PACKAGE_M153.md):
  GitHub Actions run/check event proof package.
- [atlas/BUSINESS_FLOW_EVIDENCE.md](atlas/BUSINESS_FLOW_EVIDENCE.md):
  business workflow assurance evidence model.
- [atlas/EXTERNAL_REVIEWER_PACKAGE.md](atlas/EXTERNAL_REVIEWER_PACKAGE.md):
  external reviewer package contract.
- [KNOWN_LIMITATIONS.md](KNOWN_LIMITATIONS.md): project-level maturity and
  limitation language.

## Precision Limits

These limits preserve the value of positive claims:

- Atlas support is not certification.
- Atlas support is not external audit completion.
- Atlas support is not legal compliance.
- Atlas retained evidence is not tamper-proof infrastructure.
- Atlas verification is not guaranteed safety proof.
- Atlas receipts do not prove source-system truth by themselves.
- Atlas AI-agent receipts do not prove model correctness.
- Atlas GitHub Actions receipts do not create a live integration.
- Atlas business-flow packets do not embed or certify sensitive business data.
