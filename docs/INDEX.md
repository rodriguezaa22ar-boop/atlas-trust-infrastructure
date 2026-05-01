# Atlas Documentation Index

## Purpose

Use this index when you want to understand Atlas quickly without reading the
repository in filesystem order.

## Start here

- [ATLAS_ONE_PAGE.md](ATLAS_ONE_PAGE.md): one-page explanation of what Atlas is,
  who it is for, what it does, and what it does not do.
- [../README.md](../README.md): short landing page with quick start, safety
  boundary, current maturity, and docs map.

## Start here by role

- New reader: [ATLAS_ONE_PAGE.md](ATLAS_ONE_PAGE.md)
- Security operator: [OPERATOR_GUIDE.md](OPERATOR_GUIDE.md)
- Business owner: [atlas/BUSINESS_FLOW_EVIDENCE.md](atlas/BUSINESS_FLOW_EVIDENCE.md)
- Release reviewer: [RELEASE_TRUST.md](RELEASE_TRUST.md)
- SLSA reviewer: [atlas/SLSA_CLAIM.md](atlas/SLSA_CLAIM.md)
- External reviewer: [atlas/EXTERNAL_REVIEWER_PACKAGE.md](atlas/EXTERNAL_REVIEWER_PACKAGE.md)
- Contributor: [../CONTRIBUTING.md](../CONTRIBUTING.md)
- Security reporter: [../SECURITY.md](../SECURITY.md)

## Operator workflow

- [OPERATOR_GUIDE.md](OPERATOR_GUIDE.md): end-to-end operator workflow.
- [COMMAND_REFERENCE.md](COMMAND_REFERENCE.md): detailed command reference.
- [WEB_ASSESSMENT.md](WEB_ASSESSMENT.md): bounded `atlas web assess` workflow.
- [demo/DEMO_OPERATION.md](demo/DEMO_OPERATION.md): local demo operation.

## Case studies

- [case-studies/CASE_STUDY_RELEASE_TRUST.md](case-studies/CASE_STUDY_RELEASE_TRUST.md):
  public case study for release trust as a metadata-first proof layer.
- [case-studies/CASE_STUDY_VENDOR_PAYMENT_CHANGE.md](case-studies/CASE_STUDY_VENDOR_PAYMENT_CHANGE.md):
  public business-flow case study for vendor payment change review.

## Trust lifecycle

- [TRUST_LIFECYCLE.md](TRUST_LIFECYCLE.md): scope-to-release trust chain.
- [TRUST_MODEL.md](TRUST_MODEL.md): trust anchors and verification pattern.
- [atlas/TRUST_LIFECYCLE.md](atlas/TRUST_LIFECYCLE.md): Atlas-local lifecycle
  detail.
- [atlas/TRUST_INFRASTRUCTURE_DIRECTION.md](atlas/TRUST_INFRASTRUCTURE_DIRECTION.md):
  trust-infrastructure direction for Atlas.
- [atlas/TRUST_OBJECT_MODEL.md](atlas/TRUST_OBJECT_MODEL.md): actors, objects,
  packets, schemas, freshness, verification, replay, and retention.
- [atlas/BUSINESS_FLOW_EVIDENCE.md](atlas/BUSINESS_FLOW_EVIDENCE.md):
  metadata-only business-flow evidence design.

## Release trust

- [case-studies/CASE_STUDY_RELEASE_TRUST.md](case-studies/CASE_STUDY_RELEASE_TRUST.md):
  public case study for release trust as a metadata-first proof layer.
- [RELEASE_TRUST.md](RELEASE_TRUST.md): release packet, verify, replay,
  signing, and provenance.
- [atlas/RELEASE_ARTIFACT_MANIFEST.md](atlas/RELEASE_ARTIFACT_MANIFEST.md):
  retained release artifact manifest contract and verification rules.
- [atlas/SLSA_PROVENANCE.md](atlas/SLSA_PROVENANCE.md): GitHub/Sigstore SLSA
  provenance workflow and verification contract for Atlas release artifacts.
- [atlas/SLSA_CLAIM.md](atlas/SLSA_CLAIM.md): bounded SLSA-verifiable release
  artifact claim and evidence checklist.
- [atlas/INDEPENDENT_REVIEW_READINESS.md](atlas/INDEPENDENT_REVIEW_READINESS.md):
  reviewer packet expectations for an external release-trust review.
- [atlas/EXTERNAL_REVIEWER_PACKAGE.md](atlas/EXTERNAL_REVIEWER_PACKAGE.md):
  generated metadata-only reviewer package contract and contents.
- [retention/reviews/atlas-v0.4.0-rc1-review-packet.md](retention/reviews/atlas-v0.4.0-rc1-review-packet.md):
  executable independent-review packet for the retained v0.4.0-rc1 SLSA
  evidence.
- [retention/releases/REPLAY_VERIFICATION.md](retention/releases/REPLAY_VERIFICATION.md):
  clean-checkout replay procedure.
- [atlas/PRODUCTION_READINESS.md](atlas/PRODUCTION_READINESS.md): local
  production readiness contract.

## Production readiness

- [atlas/V1_PILLAR_READINESS.md](atlas/V1_PILLAR_READINESS.md): v1 pillar
  readiness contract.
- [atlas/PRODUCTION_READINESS.md](atlas/PRODUCTION_READINESS.md): stricter
  production-readiness gates.
- [KNOWN_LIMITATIONS.md](KNOWN_LIMITATIONS.md): what Atlas still does not
  claim.

## Safety model

- [SECURITY_MODEL.md](SECURITY_MODEL.md): authorized-use boundary and
  capability tiers.
- [RESPONSIBLE_USE.md](RESPONSIBLE_USE.md): responsible-use constraints.
- [../SECURITY.md](../SECURITY.md): public vulnerability reporting rules and
  no-secrets disclosure boundary.
- [../CONTRIBUTING.md](../CONTRIBUTING.md): public contribution rules and QA
  expectations.
- [agents/AGENT_WORKFLOW.md](agents/AGENT_WORKFLOW.md): agent work protocol.

## Schemas

- [schemas/README.md](schemas/README.md): implemented JSON contracts.
- [schemas/business-flow-evidence.v1.md](schemas/business-flow-evidence.v1.md):
  optional business-flow evidence contract.
- [schemas/business-flow-packet.v1.md](schemas/business-flow-packet.v1.md):
  business-flow packet contract for Markdown and JSON packet parity.
- [schemas/business-flow-verify.v1.md](schemas/business-flow-verify.v1.md):
  machine-readable business-flow packet verification contract.
- [schemas/business-flow-assurance.v1.md](schemas/business-flow-assurance.v1.md):
  read-only business-flow assurance status contract.
- [schemas/business-flow-trust-chain.v1.md](schemas/business-flow-trust-chain.v1.md):
  machine-readable single-flow trust-chain status contract.
- [schemas/release-artifact-manifest.v1.md](schemas/release-artifact-manifest.v1.md):
  metadata-only release artifact manifest contract.
- [schemas/external-reviewer-package.v1.md](schemas/external-reviewer-package.v1.md):
  metadata-only external reviewer package manifest contract.
- [schemas/slsa-provenance.v1.md](schemas/slsa-provenance.v1.md):
  SLSA provenance readiness contract for release artifacts.
- [schemas/handoff-packet.v1.md](schemas/handoff-packet.v1.md):
  metadata-only operation handoff packet contract.
- [schemas/closeout-manifest.v1.md](schemas/closeout-manifest.v1.md):
  metadata-only closeout manifest contract.
- [schemas/accepted-risk-review-packet.v1.md](schemas/accepted-risk-review-packet.v1.md):
  metadata-only accepted-risk review packet contract.
- [schemas/advisor-prompt-packet.v1.md](schemas/advisor-prompt-packet.v1.md):
  metadata-only Advisor Packet Interface contract.
- [schemas/flow-finding-link.v1.md](schemas/flow-finding-link.v1.md):
  metadata-only business-flow finding link contract.
- [schemas/flow-validation-link.v1.md](schemas/flow-validation-link.v1.md):
  metadata-only business-flow validation link contract.
- [schemas/flow-approval-link.v1.md](schemas/flow-approval-link.v1.md):
  metadata-only business-flow approval link contract.
- [schemas/flow-retention-link.v1.md](schemas/flow-retention-link.v1.md):
  metadata-only business-flow retention link contract.
- [atlas/PACKET_FORMAT_PARITY.md](atlas/PACKET_FORMAT_PARITY.md): Markdown and
  JSON parity matrix.

## Milestones

- [retention/MILESTONE_INDEX.md](retention/MILESTONE_INDEX.md): retained
  milestone history.
- [retention/milestones/](retention/milestones/): milestone notes.

## Agent guidance

- [../AGENTS.md](../AGENTS.md): root Codex/agent guidance.
- [agents/AGENT_VALIDATION.md](agents/AGENT_VALIDATION.md): validation rules
  for agent guidance.

## Roadmap

- [ROADMAP.md](ROADMAP.md): current and future phases.
- [ATLAS_BLUEPRINT.md](ATLAS_BLUEPRINT.md): detailed architecture and milestone
  blueprint.
