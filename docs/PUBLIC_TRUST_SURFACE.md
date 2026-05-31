# Public Trust Surface

## Purpose

Atlas supports audit-ready evidence, release governance, CI integrity review,
AI-agent action review, approval integrity, evidence sufficiency review, and
reviewer decision support through replayable metadata-only proof receipts.

This public trust surface explains the review value Atlas can support now and
points reviewers to the fastest local verification paths.

## What Atlas Supports

Atlas helps reviewers inspect critical actions as bounded proof envelopes:

- replayable receipt records for important events;
- metadata-only external event imports;
- AI-agent action and result review without agent execution authority;
- GitHub Actions run/check metadata review without API calls or raw logs;
- retained release evidence and release-trust packet review;
- production-readiness review under the local Atlas contract;
- evidence sufficiency review for evidence that is `present`, `missing`,
  `stale`, or `unverifiable`;
- reviewer decision packets that connect objective, evidence status,
  verification commands, known limitations, and outside-Atlas determinations.

## Proof Receipts

Atlas proof receipts are metadata-only records for critical digital actions.
They can include event type, actor, timestamps, hashes, reviewed commit,
approval references, artifact references, replay pointers, and known
limitations.

Receipts are useful because a reviewer can run local commands that verify the
proof envelope:

```bash
./tools/atlas/bin/atlas receipt verify examples/receipt/minimal.json
./tools/atlas/bin/atlas receipt replay examples/receipt/demo-site/*.json
```

Atlas verifies receipt structure, deterministic hashes, metadata-only
boundaries, and provided replay order. This makes the action record reviewable
without embedding raw logs, secrets, prompt bodies, packet captures, or
request/response bodies.

## Reviewer Outcomes

Atlas supports reviewer action by making the evidence state visible:

- `present`: required evidence exists and local verification commands are
  available.
- `missing`: required evidence is absent and should be retained or accepted as
  a gap outside Atlas.
- `stale`: evidence exists but no longer matches the reviewed commit or proof
  state.
- `unverifiable`: evidence exists but local verification fails or cannot be
  completed.

The reviewer can then proceed with internal review, request missing evidence,
rerun verification, refresh stale retained evidence, reject a
production-readiness claim until required evidence is present, or escalate to
an external reviewer, auditor, approver, or authority.

## Review Areas

Atlas supports AI-agent action review by treating AI agents as metadata-only
event sources. It records proposed actions, reported results, optional local
model helper usage, input/output hashes, summaries, and known limitations
without storing raw prompts, raw model outputs, tool bodies, or execution
authority.

Atlas supports GitHub Actions / CI integrity review by importing local
workflow-run and check metadata through the existing generic external event
adapter. The path is local-file only: no GitHub API calls, webhooks, raw job
logs, workflow secrets, or action execution are added.

Atlas supports production-readiness review under the local Atlas contract by
mapping v1 readiness, repository cleanliness, release trust packets, artifact
manifests, signing/provenance, production dry-run evidence, reviewer packages,
and public export checks to local verification commands.

## Where To Start

- Five-minute receipt quickstart: [TRY_RECEIPTS.md](TRY_RECEIPTS.md)
- Generic event adapter quickstart:
  [TRY_GENERIC_EVENT_ADAPTER.md](TRY_GENERIC_EVENT_ADAPTER.md)
- AI-agent event quickstart:
  [TRY_AI_AGENT_EVENT_RECEIPTS.md](TRY_AI_AGENT_EVENT_RECEIPTS.md)
- GitHub Actions event proof package:
  [reviews/GITHUB_ACTIONS_EVENT_PROOF_PACKAGE_M153.md](reviews/GITHUB_ACTIONS_EVENT_PROOF_PACKAGE_M153.md)
- Trust Claim Ladder: [TRUST_CLAIM_LADDER.md](TRUST_CLAIM_LADDER.md)
- Control Objective Mapping:
  [reviews/CONTROL_OBJECTIVE_MAPPING.md](reviews/CONTROL_OBJECTIVE_MAPPING.md)
- Production Readiness Control Mapping:
  [reviews/PRODUCTION_READINESS_CONTROL_MAPPING_M156.md](reviews/PRODUCTION_READINESS_CONTROL_MAPPING_M156.md)
- Evidence Sufficiency Report:
  [reviews/EVIDENCE_SUFFICIENCY_REPORT_M158.md](reviews/EVIDENCE_SUFFICIENCY_REPORT_M158.md)
- Reviewer Decision Packet:
  [reviews/REVIEWER_DECISION_PACKET_M160.md](reviews/REVIEWER_DECISION_PACKET_M160.md)

## Precision Boundaries

Boundaries are criteria for stronger claims, not a retreat from value. Atlas
supports review by preserving the proof envelope and local verification path;
reviewers, auditors, approvers, or authorities make final determinations.

This support is not certification, legal compliance, external audit
completion, tamper-proof infrastructure, guaranteed safety, external SLSA
certification, production deployability outside the local Atlas contract,
enterprise deployment approval, runtime safety proof, model correctness proof,
or artifact correctness guarantee.

Known limitations remain part of the public trust surface because they tell a
reviewer exactly where Atlas evidence ends and outside determination begins.
See [KNOWN_LIMITATIONS.md](KNOWN_LIMITATIONS.md).
