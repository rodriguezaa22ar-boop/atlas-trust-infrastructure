# Atlas Documentation Index

## Purpose

Use this index when you want to understand Atlas quickly without reading the
repository in filesystem order.

## Start here

- [ATLAS_ONE_PAGE.md](ATLAS_ONE_PAGE.md): one-page explanation of what Atlas is,
  who it is for, what it does, and what it does not do.
- [RECEIPT_OPEN_CORE_RC.md](RECEIPT_OPEN_CORE_RC.md): receipt, replay, and
  reviewer-proof open-core RC packaging checkpoint.
- [TRY_RECEIPTS.md](TRY_RECEIPTS.md): five-minute local receipt verify and
  replay quickstart.
- [TRY_GENERIC_EVENT_ADAPTER.md](TRY_GENERIC_EVENT_ADAPTER.md): five-minute
  local generic external event import, verify, and replay quickstart.
- [TRY_AI_AGENT_EVENT_RECEIPTS.md](TRY_AI_AGENT_EVENT_RECEIPTS.md):
  five-minute local AI-agent event import, verify, and replay quickstart.
- [reviews/GITHUB_ACTIONS_RUN_RECEIPT_CANDIDATE_M151.md](reviews/GITHUB_ACTIONS_RUN_RECEIPT_CANDIDATE_M151.md):
  first real-world import-only GitHub Actions run/check receipt candidate.
- [../README.md](../README.md): short landing page with quick start, safety
  boundary, current maturity, and docs map.
- [REPOSITORY_BOUNDARY.md](REPOSITORY_BOUNDARY.md): public/private repository
  boundary and public export contract.

## Start here by role

- New reader: [ATLAS_ONE_PAGE.md](ATLAS_ONE_PAGE.md)
- Security operator: [OPERATOR_GUIDE.md](OPERATOR_GUIDE.md)
- Lab operator: [ops/DUAL_NODE_COCKPIT.md](ops/DUAL_NODE_COCKPIT.md)
- Host/runtime reviewer: [ops/PORTABILITY_CONTRACT.md](ops/PORTABILITY_CONTRACT.md)
- Business owner: [atlas/BUSINESS_FLOW_EVIDENCE.md](atlas/BUSINESS_FLOW_EVIDENCE.md)
- Release reviewer: [RELEASE_TRUST.md](RELEASE_TRUST.md)
- SLSA reviewer: [atlas/SLSA_CLAIM.md](atlas/SLSA_CLAIM.md)
- External reviewer: [atlas/EXTERNAL_REVIEWER_PACKAGE.md](atlas/EXTERNAL_REVIEWER_PACKAGE.md)
- Contributor: [../CONTRIBUTING.md](../CONTRIBUTING.md)
- Security reporter: [../SECURITY.md](../SECURITY.md)

## Operator workflow

- [OPERATOR_GUIDE.md](OPERATOR_GUIDE.md): end-to-end operator workflow.
- [ops/DUAL_NODE_COCKPIT.md](ops/DUAL_NODE_COCKPIT.md): standard cockpit
  and builder compute split with a public proof boundary.
- [ops/PORTABILITY_CONTRACT.md](ops/PORTABILITY_CONTRACT.md): any-system
  runtime rule and host/Nix proof split.
- [ops/HOST_SHELL_RUNTIME.md](ops/HOST_SHELL_RUNTIME.md): required and
  optional host-shell dependencies.
- [ops/NIX_REFERENCE_ENVIRONMENT.md](ops/NIX_REFERENCE_ENVIRONMENT.md):
  reference proof environment.
- [ops/SUPPORTED_SYSTEMS.md](ops/SUPPORTED_SYSTEMS.md): support levels for
  NixOS, generic Linux, macOS, WSL, containers, CI, source archives, and clones.
- [COMMAND_REFERENCE.md](COMMAND_REFERENCE.md): detailed command reference.
- [WEB_ASSESSMENT.md](WEB_ASSESSMENT.md): bounded `atlas web assess` workflow.
- [demo/README.md](demo/README.md): demo directory entry point and boundary.
- [demo/DEMO_OPERATION.md](demo/DEMO_OPERATION.md): synthetic metadata-only
  demo operation from target registration through release trust.
- [demo/DEMO_REVIEWER_RUNBOOK.md](demo/DEMO_REVIEWER_RUNBOOK.md): reviewer
  runbook for the demo operation and retained release evidence.
- [demo/DEMO_RECEIPT_PACKET.md](demo/DEMO_RECEIPT_PACKET.md): synthetic
  demo-site receipt packet and replay path.
- [TRY_RECEIPTS.md](TRY_RECEIPTS.md): copy-paste local receipt verify and
  replay path with expected output.
- [TRY_GENERIC_EVENT_ADAPTER.md](TRY_GENERIC_EVENT_ADAPTER.md): copy-paste
  generic external event adapter import path with expected verify and replay
  output.
- [TRY_AI_AGENT_EVENT_RECEIPTS.md](TRY_AI_AGENT_EVENT_RECEIPTS.md): copy-paste
  AI-agent event profile import path with expected verify and replay output.
- [reviews/GITHUB_ACTIONS_RUN_RECEIPT_CANDIDATE_M151.md](reviews/GITHUB_ACTIONS_RUN_RECEIPT_CANDIDATE_M151.md):
  local-file GitHub Actions run/check event receipt candidate using the
  generic adapter.

## Case studies

- [case-studies/CASE_STUDY_RELEASE_TRUST.md](case-studies/CASE_STUDY_RELEASE_TRUST.md):
  public case study for release trust as a metadata-first proof layer.
- [case-studies/CASE_STUDY_VENDOR_PAYMENT_CHANGE.md](case-studies/CASE_STUDY_VENDOR_PAYMENT_CHANGE.md):
  public business-flow case study for vendor payment change review.

## Trust lifecycle

- [REPOSITORY_BOUNDARY.md](REPOSITORY_BOUNDARY.md): public/private repository
  boundary and public export contract.
- [TRUST_LIFECYCLE.md](TRUST_LIFECYCLE.md): scope-to-release trust chain.
- [demo/DEMO_OPERATION.md](demo/DEMO_OPERATION.md): repeatable synthetic demo
  of the trust lifecycle.
- [demo/DEMO_RECEIPT_PACKET.md](demo/DEMO_RECEIPT_PACKET.md): metadata-only
  receipt replay binding for the synthetic demo path.
- [TRUST_MODEL.md](TRUST_MODEL.md): trust anchors and verification pattern.
- [RECEIPTS.md](RECEIPTS.md): M131 metadata-only portable proof receipts for
  critical digital actions, with M133 local replay and ledger binding.
- [RECEIPT_OPEN_CORE_RC.md](RECEIPT_OPEN_CORE_RC.md): reviewer-facing package
  for the current receipt/replay proof surface and M140 retained evidence.
- [TRY_RECEIPTS.md](TRY_RECEIPTS.md): fast reviewer path for verifying and
  replaying the synthetic receipt chain locally.
- [atlas/TRUST_LIFECYCLE.md](atlas/TRUST_LIFECYCLE.md): Atlas-local lifecycle
  detail.
- [atlas/TRUST_INFRASTRUCTURE_DIRECTION.md](atlas/TRUST_INFRASTRUCTURE_DIRECTION.md):
  trust-infrastructure direction for Atlas.
- [atlas/TRUST_OBJECT_MODEL.md](atlas/TRUST_OBJECT_MODEL.md): actors, objects,
  packets, schemas, freshness, verification, replay, and retention.
- [atlas/BUSINESS_FLOW_EVIDENCE.md](atlas/BUSINESS_FLOW_EVIDENCE.md):
  metadata-only business-flow evidence design.

## Governance

- [governance/CAPABILITY_MODEL.md](governance/CAPABILITY_MODEL.md): M124
  capability manifest model and validation gate.
- [governance/ADAPTER_REGISTRY.md](governance/ADAPTER_REGISTRY.md): M125
  import-only adapter registry and validation gate.
- [adapters/GENERIC_EXTERNAL_EVENT_RECEIPT_ADAPTER.md](adapters/GENERIC_EXTERNAL_EVENT_RECEIPT_ADAPTER.md):
  M143 local-file import-only adapter for converting synthetic generic external
  events into Atlas receipts.
- [adapters/AI_AGENT_EVENT_RECEIPT_PROFILE.md](adapters/AI_AGENT_EVENT_RECEIPT_PROFILE.md):
  M146 metadata-only AI-agent event profile that treats agents as event
  sources, not authorities or execution engines.
- [reviews/GITHUB_ACTIONS_RUN_RECEIPT_CANDIDATE_M151.md](reviews/GITHUB_ACTIONS_RUN_RECEIPT_CANDIDATE_M151.md):
  M151 import-only GitHub Actions run/check event candidate using the existing
  generic external event adapter.
- [TRY_GENERIC_EVENT_ADAPTER.md](TRY_GENERIC_EVENT_ADAPTER.md): M145
  five-minute local quickstart for the generic external event adapter.
- [TRY_AI_AGENT_EVENT_RECEIPTS.md](TRY_AI_AGENT_EVENT_RECEIPTS.md): M147
  five-minute local quickstart for AI-agent event receipts and optional local
  model helper metadata.
- [governance/POLICY_PLANE.md](governance/POLICY_PLANE.md): M126 policy
  decision contract and validation gate.
- [governance/APPROVAL_PLANE.md](governance/APPROVAL_PLANE.md): M127
  approval workflow contract and validation gate.
- [../ledger/README.md](../ledger/README.md): M128 evidence envelope and
  hash-ledger contract.

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
- [retention/reviews/ATLAS_V1_INTERNAL_RC_EXTERNAL_REVIEW.md](retention/reviews/ATLAS_V1_INTERNAL_RC_EXTERNAL_REVIEW.md):
  external review validation for the retained Atlas v1 Internal RC from a
  clean lab-node clone.
- [reviews/PUBLIC_REVIEWER_DRY_RUN_M142.md](reviews/PUBLIC_REVIEWER_DRY_RUN_M142.md):
  fresh public-clone reviewer dry-run for the receipt Open-Core RC path.
- [reviews/AI_AGENT_EVENT_REVIEWER_DRY_RUN_M149.md](reviews/AI_AGENT_EVENT_REVIEWER_DRY_RUN_M149.md):
  fresh public-clone reviewer dry-run for the AI-agent event receipt path.
- [reviews/AI_AGENT_EVENT_PROOF_PACKAGE_M150.md](reviews/AI_AGENT_EVENT_PROOF_PACKAGE_M150.md):
  reviewer-facing proof package for the AI-agent event receipt path.
- [reviews/GITHUB_ACTIONS_RUN_RECEIPT_CANDIDATE_M151.md](reviews/GITHUB_ACTIONS_RUN_RECEIPT_CANDIDATE_M151.md):
  first real-world import-only GitHub Actions run/check event receipt
  candidate.
- [retention/releases/REPLAY_VERIFICATION.md](retention/releases/REPLAY_VERIFICATION.md):
  clean-checkout replay procedure.
- [atlas/PRODUCTION_READINESS.md](atlas/PRODUCTION_READINESS.md): local
  production readiness contract.

## Lab retention

- [retention/lab/README.md](retention/lab/README.md): metadata-only lab
  retention records and boundary.
- [retention/lab/ATLAS_DUAL_NODE_LAB_VALIDATION_M123.md](retention/lab/ATLAS_DUAL_NODE_LAB_VALIDATION_M123.md):
  M123 dual-node lab validation retention with private host labels redacted.
- [retention/demo/M138_DEMO_RECEIPT_PACKET.md](retention/demo/M138_DEMO_RECEIPT_PACKET.md):
  retained M138 synthetic demo receipt packet checkpoint.

## Production readiness

- [atlas/V1_PILLAR_READINESS.md](atlas/V1_PILLAR_READINESS.md): v1 pillar
  readiness contract.
- [atlas/V1_INTERNAL_RC.md](atlas/V1_INTERNAL_RC.md): Atlas v1 Internal Release Candidate scope, verification checklist, and non-guarantees.
- [atlas/PRODUCTION_READINESS.md](atlas/PRODUCTION_READINESS.md): stricter
  production-readiness gates.
- [KNOWN_LIMITATIONS.md](KNOWN_LIMITATIONS.md): what Atlas still does not
  claim.

## Safety model

- [SECURITY_MODEL.md](SECURITY_MODEL.md): authorized-use boundary and
  capability tiers.
- [security/ATLAS_REVIEW_MATRIX.md](security/ATLAS_REVIEW_MATRIX.md):
  defensive review checklist for metadata, read-only, network, host, shell,
  and demo boundaries.
- [strategy/ATLAS_FAILURE_MODE_MAP.md](strategy/ATLAS_FAILURE_MODE_MAP.md):
  startup failure lessons mapped to Atlas risks and safeguards.
- [RESPONSIBLE_USE.md](RESPONSIBLE_USE.md): responsible-use constraints.
- [../SECURITY.md](../SECURITY.md): public vulnerability reporting rules and
  no-secrets disclosure boundary.
- [../CONTRIBUTING.md](../CONTRIBUTING.md): public contribution rules and QA
  expectations.
- [agents/AGENT_WORKFLOW.md](agents/AGENT_WORKFLOW.md): agent work protocol.

## Schemas

- [schemas/README.md](schemas/README.md): implemented JSON contracts.
- [../schemas/atlas.receipt.v1.schema.json](../schemas/atlas.receipt.v1.schema.json):
  M131 receipt JSON Schema for metadata-only proof records.
- [../schemas/generic-external-event.v1.schema.json](../schemas/generic-external-event.v1.schema.json):
  M143 local-file generic external event input schema for receipt import.
- [schemas/receipt-canonicalization.v1.md](schemas/receipt-canonicalization.v1.md):
  M137 deterministic receipt hash canonicalization contract.
- [schemas/SCHEMA_FREEZE_CANDIDATE.md](schemas/SCHEMA_FREEZE_CANDIDATE.md):
  M120 v1 schema freeze candidate classifications and version-bump rules.
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
- [schemas/release-replay.v1.md](schemas/release-replay.v1.md):
  machine-readable release replay result contract.
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
