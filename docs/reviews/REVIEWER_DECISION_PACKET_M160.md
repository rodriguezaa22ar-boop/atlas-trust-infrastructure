# Reviewer Decision Packet M160

## Reviewed Commit

`9d7dbca8767ab249cda29eb16c73bb31b78231ff` M159 merged checkpoint

## Purpose

Atlas supports reviewer decision paths by connecting the Trust Claim Ladder,
control-objective mapping, and evidence sufficiency report into one bounded
decision packet.

M160 turns the M154-M159 review architecture into a reviewer-facing path:

```text
review objective
-> required evidence
-> evidence sufficiency status
-> local verification commands
-> known limitations
-> reviewer decision record
```

This packet is docs/tests only. It does not add runtime behavior, a decision
engine, an approval engine, a live integration, a network collector, a database,
or a new adapter.

## Positive Support Claim

```text
Atlas supports reviewer decisions by packaging the objective, evidence status,
local verification paths, known limitations, and remaining outside-Atlas
determination into one metadata-only decision packet.
```

## Relationship To Earlier Milestones

- [TRUST_CLAIM_LADDER.md](../TRUST_CLAIM_LADDER.md) defines the positive claim
  levels and keeps boundaries as criteria for stronger claims.
- [CONTROL_OBJECTIVE_MAPPING.md](CONTROL_OBJECTIVE_MAPPING.md) maps review
  objectives to evidence, verification commands, support claims, and remaining
  outside-Atlas determinations.
- [PRODUCTION_READINESS_CONTROL_MAPPING_M156.md](PRODUCTION_READINESS_CONTROL_MAPPING_M156.md)
  applies the mapping to production-readiness review under the local Atlas
  contract.
- [EVIDENCE_SUFFICIENCY_REPORT_M158.md](EVIDENCE_SUFFICIENCY_REPORT_M158.md)
  classifies required evidence as `present`, `missing`, `stale`, or
  `unverifiable`.
- M159 protects the evidence sufficiency claim from treating gaps as approval,
  certification, compliance, deployability, external audit completion, or
  runtime safety proof.

M160 adds the reviewer decision layer after those pieces are visible.

## Decision Path

| Step | Reviewer question | Atlas support | Reviewer output |
| --- | --- | --- | --- |
| 1. Name objective | What decision is being reviewed? | Link to the objective in `CONTROL_OBJECTIVE_MAPPING.md`. | Named review objective and reviewed commit. |
| 2. Gather evidence | What evidence is required? | List required evidence from the control mapping and related proof package. | Evidence checklist. |
| 3. Assign sufficiency status | Is each evidence item `present`, `missing`, `stale`, or `unverifiable`? | Use the M158 status vocabulary and local verification commands. | Per-item evidence status with reason. |
| 4. Run verification | Which local checks support the status? | Record command paths such as receipt verify/replay, release verify/replay, reviewer package, production status, and public export. | Command summary, not raw logs. |
| 5. Record limitations | What does the proof envelope not decide? | Keep known limitations and outside-Atlas determinations visible. | Limitation and residual-risk notes. |
| 6. Record decision | What should the reviewer do next? | Provide a bounded decision vocabulary and required follow-up. | Reviewer decision record. |

## Decision Vocabulary

The decision packet uses a reviewer-owned vocabulary:

| Decision | Meaning | Required condition | Follow-up |
| --- | --- | --- | --- |
| `supported` | The evidence package supports the review objective enough for the reviewer to proceed. | Required evidence is `present`, local verification paths are named, and known limitations are visible. | Reviewer records acceptance, approval, or next process step outside Atlas. |
| `supported_with_limitations` | The evidence supports the objective with explicit residual limitations. | Evidence is mostly `present`; remaining limitations are visible and accepted by the reviewer. | Reviewer records accepted limitations and any monitoring or follow-up. |
| `needs_refresh` | Evidence exists but is stale or tied to an older reviewed state. | One or more required items are `stale`. | Regenerate or refresh evidence before relying on the objective. |
| `needs_remediation` | Required evidence is missing or incomplete. | One or more required items are `missing`. | Retain the missing evidence or document why the gap is accepted outside Atlas. |
| `needs_investigation` | Evidence exists but cannot be verified locally. | One or more required items are `unverifiable`. | Resolve verifier failures, malformed artifacts, unavailable references, or hash/signature issues. |
| `outside_scope` | The requested determination is outside the Atlas support claim. | The question asks Atlas to decide source truth, authorization, compliance, certification, audit completion, deployment approval, or model/runtime safety. | Route the decision to the appropriate reviewer, auditor, approver, or authority. |

Atlas records support for the proof envelope. The reviewer owns the decision.

## Supported Reviewer Actions

The decision packet supports positive reviewer action when the evidence state is
visible and bounded. Supported decisions include:

- `proceed with internal review` when required evidence is `present`, local
  verification commands are named, and known limitations remain visible.
- `request missing evidence` when required evidence is `missing`.
- `rerun verification` when a command summary is unavailable, malformed, or
  tied to an unverifiable artifact.
- `refresh stale retained evidence` when evidence exists but no longer matches
  the reviewed commit, release packet, manifest, or retained proof state.
- `reject production-readiness claim until required evidence is present` when
  required local Atlas contract evidence is absent.
- `escalate to external reviewer/auditor/authority` when the requested
  determination belongs outside Atlas.

These actions keep the packet decision-oriented without making Atlas the
decision authority.

## Unsupported Decision Claims

The packet also makes unsupported decisions explicit. The following conclusions
remain outside Atlas and must not be recorded as Atlas determinations:

- `externally certified`
- `legally compliant`
- `tamper-proof`
- `guaranteed safe`
- `production deployable outside the local Atlas contract`
- `external SLSA certified`
- `model correctness proven`
- `runtime safety proven`

Atlas can preserve the proof envelope and surface whether evidence is present,
missing, stale, or unverifiable. Reviewers, auditors, approvers, or authorities
make any external certification, compliance, deployment, safety, model, or
runtime determination.

## Production-Readiness Decision Packet Shape

This packet applies first to:

```text
production-readiness review under the local Atlas contract
```

Reviewer-facing packet shape:

```text
schema_label: reviewer_decision_packet_m160
review_objective: production-readiness review under the local Atlas contract
reviewed_commit: <commit>
claim_ladder_level: Level 4 evidence sufficiency support -> Level 5 external assurance support
control_mapping: docs/reviews/PRODUCTION_READINESS_CONTROL_MAPPING_M156.md
evidence_sufficiency_report: docs/reviews/EVIDENCE_SUFFICIENCY_REPORT_M158.md
evidence_items:
  - id: v1_internal_readiness
    status: present | missing | stale | unverifiable
    verification_commands:
      - ./tools/atlas/bin/atlas v1 status --strict
    summary: metadata-only summary
    reviewer_follow_up: ...
known_limitations:
  - ...
recommended_decision: supported | supported_with_limitations | needs_refresh | needs_remediation | needs_investigation | outside_scope
outside_atlas_determination:
  - release approval
  - deployment approval
  - signer authority
  - source-system truth
  - artifact correctness
  - audit completion
  - legal/compliance conclusion
```

This is a documentation contract for reviewer packets. It is not a new CLI
schema and does not add runtime behavior.

## Verification Commands To Reference

For the production-readiness objective, a reviewer decision packet can cite:

```bash
./tools/atlas/bin/atlas production status --strict --explain
./tools/atlas/bin/atlas v1 status --strict
git status --short --branch
git rev-list --left-right --count HEAD...@{u}
./tools/atlas/bin/atlas release verify <release-packet> --commit <commit>
./tools/atlas/bin/atlas release manifest-verify <manifest> --commit <commit>
./tools/atlas/bin/atlas release replay <release-packet> --json
git tag -v <tag>
./tools/atlas/bin/atlas reviewer package full-capability-review
./bin/export-public-trust --check
```

For receipt-backed event objectives, a reviewer decision packet can cite:

```bash
./tools/atlas/bin/atlas receipt import-generic-event <event.json> --out <receipt.json>
./tools/atlas/bin/atlas receipt verify <receipt.json>
./tools/atlas/bin/atlas receipt replay <receipt-1.json> <receipt-2.json>
```

## What Atlas Supports

Atlas supports reviewer decisions by making the following visible:

- the review objective;
- the reviewed commit;
- the mapped control objective;
- required evidence;
- evidence sufficiency status;
- local verification commands;
- metadata-only command summaries;
- known limitations;
- outside-Atlas determinations;
- reviewer follow-up for gaps.

## What Atlas Verifies

Atlas can verify the local proof envelope when the referenced commands are run:

- receipt structure, hashes, metadata-only boundary, and replay order;
- generic external event import boundaries;
- release packet and release manifest metadata;
- production status gate outputs;
- reviewer package generation;
- public export contract checks;
- evidence status visibility for `present`, `missing`, `stale`, or
  `unverifiable` items.

## Reviewer Determinations

The reviewer, auditor, approver, or authority decides:

- whether the evidence satisfies the objective;
- whether missing evidence blocks the decision;
- whether stale evidence must be refreshed;
- whether unverifiable evidence can be remediated;
- whether limitations can be accepted as residual risk;
- whether release approval, deployment approval, audit completion, legal
  conclusion, compliance conclusion, signer authority, source-system truth,
  artifact correctness, model correctness, or runtime safety is established by
  some outside process.

## Reviewer Checklist

- Confirm the decision packet names the review objective.
- Confirm the reviewed commit is recorded.
- Confirm the packet references the Trust Claim Ladder.
- Confirm the packet references the control-objective mapping.
- Confirm the packet references the evidence sufficiency report.
- Confirm each required evidence item has exactly one status:
  `present`, `missing`, `stale`, or `unverifiable`.
- Confirm local verification commands are named.
- Confirm summaries are metadata-only and do not embed raw logs, secrets,
  private keys, tokens, packet captures, raw requests, raw responses, raw
  prompts, raw model outputs, or raw terminal dumps.
- Confirm gaps map to `needs_refresh`, `needs_remediation`,
  `needs_investigation`, or `outside_scope` instead of being treated as
  approval.
- Confirm known limitations and outside-Atlas determinations remain visible.

## Known Limitations

- M160 is docs/tests only.
- M160 does not add a decision-packet CLI command.
- M160 does not add runtime behavior, a database, server, web UI, network
  collector, live integration, or adapter.
- M160 does not mutate evidence, repositories, release packets, receipts, or
  reviewer packages.
- M160 does not decide authorization, source-system truth, artifact
  correctness, model correctness, runtime safety, release approval, deployment
  approval, legal compliance, compliance conclusion, external audit completion,
  certification, or residual risk acceptance.
