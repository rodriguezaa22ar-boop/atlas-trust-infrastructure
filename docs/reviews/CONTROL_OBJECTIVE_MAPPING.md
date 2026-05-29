# Control Objective Mapping

Atlas supports control-objective review by mapping receipts, adapters, proof
packages, release packets, approval records, and business-flow packets to
positive support claims. Each mapping names the review objective, evidence
Atlas can provide, verification commands, the positive support claim, and the
remaining outside-Atlas determination.

## Summary

| Review objective | Evidence Atlas can provide | Verification commands | Positive support claim | Remaining outside-Atlas determination |
| --- | --- | --- | --- | --- |
| AI-agent action governance | AI-agent profile, proposed-action/result examples, M148 regression, M150 proof package, linked receipts. | `atlas receipt import-generic-event`; `atlas receipt verify`; `atlas receipt replay`. | Atlas supports review of AI-agent activity as metadata-only event-source evidence. | Authorization, approval sufficiency, model correctness, usefulness, and risk acceptance. |
| GitHub Actions / CI integrity | GitHub Actions run/check examples, M151 candidate, M152 regression, M153 proof package, linked receipts. | `atlas receipt import-generic-event`; `atlas receipt verify`; `atlas receipt replay`. | Atlas supports review of CI run/check metadata as local-file, import-only receipts. | Source-system truth, run authority, CI policy acceptance, and external GitHub-side evidence needs. |
| release governance | Release packet, release manifest, signed tag metadata, retained SLSA reference metadata when present, release replay output. | `atlas release verify`; `atlas release manifest-verify`; `atlas release replay`; `git tag -v`. | Atlas supports review of retained release evidence and replayable release-trust state. | Release approval, deployment decision, external release review, certification, and residual risk acceptance. |
| production-readiness review | Production-readiness contract, v1 readiness, clean/synced repo state, release trust packet, artifact manifest, signing/provenance, production dry-run, reviewer package, public export check. | `atlas production status --strict --explain`; `atlas v1 status --strict`; `atlas release verify`; `atlas release manifest-verify`; `atlas reviewer package`; `bin/export-public-trust --check`. | Atlas supports production-readiness review under the local Atlas contract with retained, verifiable release evidence. | External production certification, deployment approval, external audit completion, legal compliance, artifact correctness, and residual risk acceptance. |
| approval integrity | Approval event JSON, policy refs, receipt `approval_refs`, requester/approver/risk/scope/expiry/rationale metadata. | `atlas approval verify`; `atlas policy evaluate`; `atlas receipt verify`; `atlas receipt replay`. | Atlas supports review of approval evidence linked to governed actions. | Approver authority, rule-of-engagement sufficiency, policy interpretation, and risk acceptance. |
| audit readiness | Reviewer package, public export manifest, proof packages, retained milestones, known limitations. | `atlas reviewer package`; `bin/export-public-trust --check`; receipt and release verifier commands. | Atlas supports cloneable, bounded review of public trust evidence. | Audit objective definition, evidence sufficiency, external audit completion, and follow-up scope. |
| business workflow assurance | Business-flow records, control objective labels, evidence/finding/validation/approval/retention links, flow packet, assurance status. | `atlas flow packet`; `atlas flow verify`; `atlas flow assurance`; `atlas op trust-chain`. | Atlas supports review of workflow evidence coverage without embedding sensitive business data. | Business control effectiveness, process owner acceptance, compliance conclusion, and remediation priority. |

## AI-Agent Action Governance

Atlas supports AI-agent action governance by representing AI-agent proposed
actions and reported results as metadata-only event-source receipts. The
profile uses `generic.external_event.v1` and keeps raw prompts, raw model
output, system prompts, tool output bodies, and tool-call raw bodies outside
the receipt.

Evidence Atlas can provide:

- [adapters/AI_AGENT_EVENT_RECEIPT_PROFILE.md](../adapters/AI_AGENT_EVENT_RECEIPT_PROFILE.md)
- [reviews/AI_AGENT_EVENT_PROOF_PACKAGE_M150.md](AI_AGENT_EVENT_PROOF_PACKAGE_M150.md)
- `examples/adapters/generic-external-event/ai-agent-action-event.json`
- `examples/adapters/generic-external-event/ai-agent-result-event.json`
- [retention/milestones/MILESTONE_148.md](../retention/milestones/MILESTONE_148.md)

Verification commands:

```bash
./tools/atlas/bin/atlas receipt import-generic-event examples/adapters/generic-external-event/ai-agent-action-event.json --out /tmp/ai-agent-action-receipt.json
./tools/atlas/bin/atlas receipt verify /tmp/ai-agent-action-receipt.json
./tools/atlas/bin/atlas receipt replay /tmp/ai-agent-action-receipt.json /tmp/ai-agent-result-receipt.json
```

Positive support claim:

```text
Atlas supports review of AI-agent activity as event-source evidence with
metadata-only receipts and replayable proposed-action to result linkage.
```

Remaining outside-Atlas determination:

- whether the activity was authorized;
- whether the human or policy approval was sufficient;
- whether the model output was useful or correct;
- whether residual risk is accepted.

## GitHub Actions / CI Integrity

Atlas supports CI integrity review by importing GitHub Actions run/check
metadata from local JSON files through the existing generic adapter. This path
does not call the GitHub API, receive webhooks, execute actions, or embed raw
logs.

M152 keeps GitHub token-shaped markers, webhook secret markers, raw logs, raw
job output, raw workflow output, raw request bodies, raw response bodies, and
environment secret fields outside accepted receipts.

Evidence Atlas can provide:

- [reviews/GITHUB_ACTIONS_RUN_RECEIPT_CANDIDATE_M151.md](GITHUB_ACTIONS_RUN_RECEIPT_CANDIDATE_M151.md)
- [reviews/GITHUB_ACTIONS_EVENT_PROOF_PACKAGE_M153.md](GITHUB_ACTIONS_EVENT_PROOF_PACKAGE_M153.md)
- `examples/adapters/generic-external-event/github-actions-run-event.json`
- `examples/adapters/generic-external-event/github-actions-check-event.json`
- [retention/milestones/MILESTONE_152.md](../retention/milestones/MILESTONE_152.md)

Verification commands:

```bash
./tools/atlas/bin/atlas receipt import-generic-event examples/adapters/generic-external-event/github-actions-run-event.json --out /tmp/github-actions-run-receipt.json
./tools/atlas/bin/atlas receipt verify /tmp/github-actions-run-receipt.json
./tools/atlas/bin/atlas receipt replay /tmp/github-actions-run-receipt.json /tmp/github-actions-check-receipt.json
```

Positive support claim:

```text
Atlas supports review of GitHub Actions run/check metadata as local-file,
metadata-only receipts with linked replay.
```

Remaining outside-Atlas determination:

- whether the CI run/check is authoritative;
- whether the source-system event exists and is complete;
- whether CI evidence satisfies release or change policy;
- whether additional GitHub-side evidence is required.

## Release Governance

Atlas supports release governance by retaining release packets, release
manifests, signed tag metadata, provenance references when available, and
replayable release-trust summaries.

Evidence Atlas can provide:

- [RELEASE_TRUST.md](../RELEASE_TRUST.md)
- [atlas/RELEASE_ARTIFACT_MANIFEST.md](../atlas/RELEASE_ARTIFACT_MANIFEST.md)
- [atlas/SLSA_CLAIM.md](../atlas/SLSA_CLAIM.md)
- [atlas/EXTERNAL_REVIEWER_PACKAGE.md](../atlas/EXTERNAL_REVIEWER_PACKAGE.md)
- retained release packets and manifests referenced by the release evidence.

Verification commands:

```bash
./tools/atlas/bin/atlas release verify <release-packet> --commit <commit>
./tools/atlas/bin/atlas release manifest-verify <manifest> --commit <commit>
./tools/atlas/bin/atlas release replay <release-packet> --json
git tag -v <tag>
```

Positive support claim:

```text
Atlas supports review of retained release evidence and release-trust replay
from local metadata.
```

Remaining outside-Atlas determination:

- whether release evidence satisfies release policy;
- whether deployment is approved;
- whether external artifact retrieval is needed;
- whether an external assurance process grants certification or other formal
  conclusion.

## Production-Readiness Review

Atlas supports production-readiness review by mapping the local production
contract to retained readiness, release, artifact, provenance, dry-run,
reviewer, and public export evidence.

Evidence Atlas can provide:

- [atlas/PRODUCTION_READINESS.md](../atlas/PRODUCTION_READINESS.md)
- [reviews/PRODUCTION_READINESS_CONTROL_MAPPING_M156.md](PRODUCTION_READINESS_CONTROL_MAPPING_M156.md)
- [TRUST_CLAIM_LADDER.md](../TRUST_CLAIM_LADDER.md)
- [atlas/V1_PILLAR_READINESS.md](../atlas/V1_PILLAR_READINESS.md)
- [RELEASE_TRUST.md](../RELEASE_TRUST.md)
- [atlas/RELEASE_ARTIFACT_MANIFEST.md](../atlas/RELEASE_ARTIFACT_MANIFEST.md)
- [atlas/SLSA_PROVENANCE.md](../atlas/SLSA_PROVENANCE.md)
- [atlas/SLSA_CLAIM.md](../atlas/SLSA_CLAIM.md)
- [atlas/EXTERNAL_REVIEWER_PACKAGE.md](../atlas/EXTERNAL_REVIEWER_PACKAGE.md)
- [KNOWN_LIMITATIONS.md](../KNOWN_LIMITATIONS.md)
- retained release packets under `docs/retention/releases/`
- retained production dry-run notes under `docs/retention/production/`
- `exports/public-trust-manifest.json`

Verification commands:

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

Positive support claim:

```text
Atlas supports production-readiness review under the local Atlas contract with
retained, metadata-only, verifiable evidence for readiness, release trust,
artifact manifests, signing/provenance, dry-run evidence, reviewer package
generation, and public export checks.
```

Remaining outside-Atlas determination:

- whether the local contract is sufficient for a specific release or
  deployment decision;
- whether signing identity and provenance meet external authority expectations;
- whether artifact contents and distribution channels are accepted;
- whether dry-run evidence is realistic and sufficient;
- whether external audit, compliance, or production approval is granted.

## Approval Integrity

Atlas supports approval integrity by making approval metadata inspectable and
referenceable from receipts, policy decisions, and replay chains.

Evidence Atlas can provide:

- [governance/APPROVAL_PLANE.md](../governance/APPROVAL_PLANE.md)
- approval event JSON;
- policy refs;
- requester, approver, capability, risk, scope, expiry, rationale, and
  rollback metadata;
- receipt `approval_refs`.

Verification commands:

```bash
./tools/atlas/bin/atlas approval verify approval-event.json
./tools/atlas/bin/atlas policy evaluate atlas.agent.tool.exec --scope agent-runtime --approval-event approval-approved-event.json --json
./tools/atlas/bin/atlas receipt verify approval-linked-receipt.json
./tools/atlas/bin/atlas receipt replay receipt-1.json receipt-2.json
```

Positive support claim:

```text
Atlas supports review of approval evidence linked to governed actions.
```

Remaining outside-Atlas determination:

- whether the approver had authority;
- whether approval timing and scope satisfy policy;
- whether rule-of-engagement requirements were met;
- whether residual risk is accepted.

## Audit Readiness

Atlas supports audit readiness by keeping the public trust surface cloneable,
metadata-only, and reproducible through reviewer packages, proof packages,
public export checks, retained milestones, and known limitations.

Evidence Atlas can provide:

- [atlas/EXTERNAL_REVIEWER_PACKAGE.md](../atlas/EXTERNAL_REVIEWER_PACKAGE.md)
- [TRUST_CLAIM_LADDER.md](../TRUST_CLAIM_LADDER.md)
- [KNOWN_LIMITATIONS.md](../KNOWN_LIMITATIONS.md)
- public export manifest;
- retained milestone notes;
- proof packages for the reviewed path.

Verification commands:

```bash
./tools/atlas/bin/atlas reviewer package full-capability-review
./bin/export-public-trust --check
./tools/atlas/bin/atlas receipt verify <receipt>
./tools/atlas/bin/atlas release verify <release-packet> --commit <commit>
```

Positive support claim:

```text
Atlas supports cloneable audit-readiness review over bounded public trust
evidence.
```

Remaining outside-Atlas determination:

- whether the audit objective is satisfied;
- whether evidence is sufficient;
- whether external audit completion is granted;
- what follow-up or remediation is required.

## Business Workflow Assurance

Atlas supports business workflow assurance by linking business-flow records to
metadata-only evidence, findings, validations, approvals, retention records,
control objective labels, and trust-chain summaries without embedding sensitive
business records.

Evidence Atlas can provide:

- [atlas/BUSINESS_FLOW_EVIDENCE.md](../atlas/BUSINESS_FLOW_EVIDENCE.md)
- [schemas/business-flow-evidence.v1.md](../schemas/business-flow-evidence.v1.md)
- [schemas/business-flow-packet.v1.md](../schemas/business-flow-packet.v1.md)
- [schemas/business-flow-assurance.v1.md](../schemas/business-flow-assurance.v1.md)
- business-flow packet and assurance outputs generated from local metadata.

Verification commands:

```bash
./tools/atlas/bin/atlas flow packet <flow-id> --out flow-packet.md
./tools/atlas/bin/atlas flow verify flow-packet.md --json
./tools/atlas/bin/atlas flow assurance --json
./tools/atlas/bin/atlas op trust-chain <operation> --strict --json
```

Positive support claim:

```text
Atlas supports review of business workflow evidence coverage and freshness
through metadata-only packets and trust-chain summaries.
```

Remaining outside-Atlas determination:

- whether the mapped control objective is effective;
- whether process owner evidence is sufficient;
- whether remediation is required;
- whether legal, audit, or compliance conclusions are granted.

## Precision Limits

The positive claims above keep these limits visible:

- Atlas support is not certification.
- Atlas support is not external audit completion.
- Atlas support is not legal compliance.
- Atlas retained evidence is not tamper-proof infrastructure.
- Atlas verification is not guaranteed safety proof.
- Atlas receipts verify local metadata and hash linkage; they do not prove
  source-system truth by themselves.
- Atlas proof packages guide review; they do not replace reviewer judgment.
