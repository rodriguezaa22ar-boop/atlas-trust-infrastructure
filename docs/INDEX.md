# Atlas Documentation Index

## Purpose

Use this index when you want to understand Atlas quickly without reading the
repository in filesystem order.

## Start here

- [ATLAS_ONE_PAGE.md](ATLAS_ONE_PAGE.md): one-page explanation of what Atlas is,
  who it is for, what it does, and what it does not do.
- [PUBLIC_TRUST_SURFACE.md](PUBLIC_TRUST_SURFACE.md): proof-to-value public
  trust surface for audit-ready evidence, release governance, CI integrity
  review, AI-agent action review, evidence sufficiency, and reviewer decision
  support.
- [workflows/ORG_CI_RELEASE_REVIEW_WORKFLOW_M164.md](workflows/ORG_CI_RELEASE_REVIEW_WORKFLOW_M164.md):
  one-day organization-facing CI release review workflow using local
  GitHub Actions metadata receipts, evidence sufficiency, and reviewer decision
  support.
- [REVIEWER_QUICKSTART.md](REVIEWER_QUICKSTART.md): simplified path from fresh
  clone to first verify, first replay, GitHub Actions metadata import,
  evidence sufficiency review, and reviewer decision summary.
- [architecture/SCALE_AND_STORAGE_STRATEGY_M170.md](architecture/SCALE_AND_STORAGE_STRATEGY_M170.md):
  scale and storage strategy for larger metadata-only receipt volumes,
  indexing, batch verification, batch replay, archive rotation, and future
  collector/verifier boundaries without adding storage runtime.
- [governance/CAPABILITY_MANIFEST_M172.md](governance/CAPABILITY_MANIFEST_M172.md):
  capability manifest draft mapping recognized Atlas actions to capability
  class, approval posture, emitted evidence, and blocked-action boundaries.
- [governance/ADAPTER_REGISTRY_M174.md](governance/ADAPTER_REGISTRY_M174.md):
  adapter registry draft defining metadata-only, default-deny, non-live
  external-system adapter contracts before runtime execution.
- [governance/POLICY_PLANE_M176.md](governance/POLICY_PLANE_M176.md):
  policy plane draft defining default-deny, metadata-only policy inputs,
  decisions, and bundles before runtime policy enforcement.
- [governance/APPROVAL_PLANE_M178.md](governance/APPROVAL_PLANE_M178.md):
  approval plane draft defining metadata-only approval states, reviewer
  workflows, expiration, rejection, escalation, and break-glass documentation
  before approval engine execution.
- [governance/EVIDENCE_ENVELOPE_SCHEMA_M180.md](governance/EVIDENCE_ENVELOPE_SCHEMA_M180.md):
  evidence-envelope schema draft defining the shared metadata-only record shape
  for future capability, adapter, policy, approval, workflow, receipt, and
  reviewer evidence records before runtime evidence collection.
- [reviews/ADOPTION_FRICTION_DRY_RUN_M167.md](reviews/ADOPTION_FRICTION_DRY_RUN_M167.md):
  retained adoption dry-run for following the CI release review workflow from a
  fresh clone without live builder help.
- [RECEIPT_OPEN_CORE_RC.md](RECEIPT_OPEN_CORE_RC.md): receipt, replay, and
  reviewer-proof open-core RC packaging checkpoint.
- [TRUST_CLAIM_LADDER.md](TRUST_CLAIM_LADDER.md): positive claim ladder
  mapping Atlas receipts, adapters, proof packages, and reviewer workflows to
  review objectives.
- [reviews/PRODUCTION_READINESS_CONTROL_MAPPING_M156.md](reviews/PRODUCTION_READINESS_CONTROL_MAPPING_M156.md):
  production-readiness control mapping under the local Atlas contract.
- [reviews/EVIDENCE_SUFFICIENCY_REPORT_M158.md](reviews/EVIDENCE_SUFFICIENCY_REPORT_M158.md):
  reviewer-facing evidence sufficiency report for present, missing, stale, and
  unverifiable objective evidence.
- [reviews/REVIEWER_DECISION_PACKET_M160.md](reviews/REVIEWER_DECISION_PACKET_M160.md):
  reviewer-facing decision packet path from objective, evidence status, local
  verification, known limitations, and outside-Atlas determination.
- [reviews/REVIEWER_PLAIN_ENGLISH_OUTPUT_M166.md](reviews/REVIEWER_PLAIN_ENGLISH_OUTPUT_M166.md):
  plain-English reader mode for managers, auditors, reviewers, security
  leaders, and business stakeholders.
- [TRY_RECEIPTS.md](TRY_RECEIPTS.md): five-minute local receipt verify and
  replay quickstart.
- [TRY_GENERIC_EVENT_ADAPTER.md](TRY_GENERIC_EVENT_ADAPTER.md): five-minute
  local generic external event import, verify, and replay quickstart.
- [TRY_AI_AGENT_EVENT_RECEIPTS.md](TRY_AI_AGENT_EVENT_RECEIPTS.md):
  five-minute local AI-agent event import, verify, and replay quickstart.
- [reviews/GITHUB_ACTIONS_RUN_RECEIPT_CANDIDATE_M151.md](reviews/GITHUB_ACTIONS_RUN_RECEIPT_CANDIDATE_M151.md):
  first real-world import-only GitHub Actions run/check receipt candidate.
- [reviews/GITHUB_ACTIONS_EVENT_PROOF_PACKAGE_M153.md](reviews/GITHUB_ACTIONS_EVENT_PROOF_PACKAGE_M153.md):
  reviewer-facing proof package for the GitHub Actions run/check event receipt
  path.
- [../README.md](../README.md): short landing page with quick start, safety
  boundary, current maturity, and docs map.
- [REPOSITORY_BOUNDARY.md](REPOSITORY_BOUNDARY.md): public/private repository
  boundary and public export contract.

## Start here by role

- New reader: [ATLAS_ONE_PAGE.md](ATLAS_ONE_PAGE.md)
- Public trust reviewer: [PUBLIC_TRUST_SURFACE.md](PUBLIC_TRUST_SURFACE.md)
- First-time reviewer: [REVIEWER_QUICKSTART.md](REVIEWER_QUICKSTART.md)
- Organization CI release reviewer: [workflows/ORG_CI_RELEASE_REVIEW_WORKFLOW_M164.md](workflows/ORG_CI_RELEASE_REVIEW_WORKFLOW_M164.md)
- Adoption dry-run reviewer: [reviews/ADOPTION_FRICTION_DRY_RUN_M167.md](reviews/ADOPTION_FRICTION_DRY_RUN_M167.md)
- Security operator: [OPERATOR_GUIDE.md](OPERATOR_GUIDE.md)
- Lab operator: [ops/DUAL_NODE_COCKPIT.md](ops/DUAL_NODE_COCKPIT.md)
- Host/runtime reviewer: [ops/PORTABILITY_CONTRACT.md](ops/PORTABILITY_CONTRACT.md)
- Business owner: [atlas/BUSINESS_FLOW_EVIDENCE.md](atlas/BUSINESS_FLOW_EVIDENCE.md)
- Release reviewer: [RELEASE_TRUST.md](RELEASE_TRUST.md)
- SLSA reviewer: [atlas/SLSA_CLAIM.md](atlas/SLSA_CLAIM.md)
- External reviewer: [atlas/EXTERNAL_REVIEWER_PACKAGE.md](atlas/EXTERNAL_REVIEWER_PACKAGE.md)
- Production readiness reviewer: [reviews/PRODUCTION_READINESS_CONTROL_MAPPING_M156.md](reviews/PRODUCTION_READINESS_CONTROL_MAPPING_M156.md)
- Evidence sufficiency reviewer: [reviews/EVIDENCE_SUFFICIENCY_REPORT_M158.md](reviews/EVIDENCE_SUFFICIENCY_REPORT_M158.md)
- Decision reviewer: [reviews/REVIEWER_DECISION_PACKET_M160.md](reviews/REVIEWER_DECISION_PACKET_M160.md)
- Plain-English reviewer: [reviews/REVIEWER_PLAIN_ENGLISH_OUTPUT_M166.md](reviews/REVIEWER_PLAIN_ENGLISH_OUTPUT_M166.md)
- Control reviewer: [reviews/CONTROL_OBJECTIVE_MAPPING.md](reviews/CONTROL_OBJECTIVE_MAPPING.md)
- Scale/storage reviewer: [architecture/SCALE_AND_STORAGE_STRATEGY_M170.md](architecture/SCALE_AND_STORAGE_STRATEGY_M170.md)
- Capability governance reviewer: [governance/CAPABILITY_MANIFEST_M172.md](governance/CAPABILITY_MANIFEST_M172.md)
- Adapter governance reviewer: [governance/ADAPTER_REGISTRY_M174.md](governance/ADAPTER_REGISTRY_M174.md)
- Policy governance reviewer: [governance/POLICY_PLANE_M176.md](governance/POLICY_PLANE_M176.md)
- Approval governance reviewer: [governance/APPROVAL_PLANE_M178.md](governance/APPROVAL_PLANE_M178.md)
- Evidence governance reviewer: [governance/EVIDENCE_ENVELOPE_SCHEMA_M180.md](governance/EVIDENCE_ENVELOPE_SCHEMA_M180.md)
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
- [REVIEWER_QUICKSTART.md](REVIEWER_QUICKSTART.md): simplified reviewer path
  for first verify, first replay, GitHub Actions metadata import, evidence
  sufficiency review, and decision summary.
- [TRY_GENERIC_EVENT_ADAPTER.md](TRY_GENERIC_EVENT_ADAPTER.md): copy-paste
  generic external event adapter import path with expected verify and replay
  output.
- [TRY_AI_AGENT_EVENT_RECEIPTS.md](TRY_AI_AGENT_EVENT_RECEIPTS.md): copy-paste
  AI-agent event profile import path with expected verify and replay output.
- [reviews/GITHUB_ACTIONS_RUN_RECEIPT_CANDIDATE_M151.md](reviews/GITHUB_ACTIONS_RUN_RECEIPT_CANDIDATE_M151.md):
  local-file GitHub Actions run/check event receipt candidate using the
  generic adapter.
- [reviews/GITHUB_ACTIONS_EVENT_PROOF_PACKAGE_M153.md](reviews/GITHUB_ACTIONS_EVENT_PROOF_PACKAGE_M153.md):
  proof package for importing, verifying, replaying, and reviewing the GitHub
  Actions metadata-only receipt path.
- [workflows/ORG_CI_RELEASE_REVIEW_WORKFLOW_M164.md](workflows/ORG_CI_RELEASE_REVIEW_WORKFLOW_M164.md):
  one-day adoption workflow for trying Atlas on one CI release review.
- [reviews/ADOPTION_FRICTION_DRY_RUN_M167.md](reviews/ADOPTION_FRICTION_DRY_RUN_M167.md):
  retained dry-run for testing adoption friction, expected outputs, evidence
  sufficiency understanding, and reviewer decision clarity.

## Case studies

- [case-studies/CASE_STUDY_RELEASE_TRUST.md](case-studies/CASE_STUDY_RELEASE_TRUST.md):
  public case study for release trust as a metadata-first proof layer.
- [case-studies/CASE_STUDY_VENDOR_PAYMENT_CHANGE.md](case-studies/CASE_STUDY_VENDOR_PAYMENT_CHANGE.md):
  public business-flow case study for vendor payment change review.

## Trust lifecycle

- [REPOSITORY_BOUNDARY.md](REPOSITORY_BOUNDARY.md): public/private repository
  boundary and public export contract.
- [TRUST_LIFECYCLE.md](TRUST_LIFECYCLE.md): scope-to-release trust chain.
- [PUBLIC_TRUST_SURFACE.md](PUBLIC_TRUST_SURFACE.md): public-facing
  proof-to-value summary and starting points for reviewer verification.
- [REVIEWER_QUICKSTART.md](REVIEWER_QUICKSTART.md): first-reviewer path that
  reduces adoption friction from clone through verify, replay, event import,
  evidence sufficiency, and decision summary.
- [workflows/ORG_CI_RELEASE_REVIEW_WORKFLOW_M164.md](workflows/ORG_CI_RELEASE_REVIEW_WORKFLOW_M164.md):
  organization-facing CI release review workflow that connects proof receipts,
  evidence sufficiency, and reviewer decision support.
- [reviews/ADOPTION_FRICTION_DRY_RUN_M167.md](reviews/ADOPTION_FRICTION_DRY_RUN_M167.md):
  internal adoption friction dry-run for the one-day CI release review path.
- [demo/DEMO_OPERATION.md](demo/DEMO_OPERATION.md): repeatable synthetic demo
  of the trust lifecycle.
- [demo/DEMO_RECEIPT_PACKET.md](demo/DEMO_RECEIPT_PACKET.md): metadata-only
  receipt replay binding for the synthetic demo path.
- [TRUST_MODEL.md](TRUST_MODEL.md): trust anchors and verification pattern.
- [TRUST_CLAIM_LADDER.md](TRUST_CLAIM_LADDER.md): positive review claim
  ladder for receipts, adapters, proof packages, and reviewer workflows.
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
- [architecture/SCALE_AND_STORAGE_STRATEGY_M170.md](architecture/SCALE_AND_STORAGE_STRATEGY_M170.md):
  architecture strategy for scaling receipt storage, indexes, archives,
  checkpoints, batch verification, batch replay, and reviewer queries while
  preserving file-backed source-of-truth receipts.

## Governance

- [governance/CAPABILITY_MANIFEST_M172.md](governance/CAPABILITY_MANIFEST_M172.md):
  M172 capability manifest draft for recognized actions, classes, approval
  posture, evidence emissions, and blocked-action boundaries before runtime
  enforcement.
- [governance/CAPABILITY_MODEL.md](governance/CAPABILITY_MODEL.md): M124
  capability manifest model and validation gate.
- [governance/ADAPTER_REGISTRY_M174.md](governance/ADAPTER_REGISTRY_M174.md):
  M174 adapter registry draft for metadata-only, non-live external-system
  adapter contracts.
- [governance/ADAPTER_REGISTRY.md](governance/ADAPTER_REGISTRY.md): stable
  adapter registry entry point and validation gate.
- [governance/POLICY_PLANE_M176.md](governance/POLICY_PLANE_M176.md):
  M176 policy plane draft for capability, adapter, approval, and evidence
  decisions without runtime policy enforcement.
- [governance/APPROVAL_PLANE_M178.md](governance/APPROVAL_PLANE_M178.md):
  M178 approval plane draft for approval states, reviewer workflows,
  expiration, rejection, escalation, break-glass documentation, and
  metadata-only approval evidence before workflow execution.
- [governance/EVIDENCE_ENVELOPE_SCHEMA_M180.md](governance/EVIDENCE_ENVELOPE_SCHEMA_M180.md):
  M180 evidence-envelope schema draft for metadata-only capability, adapter,
  policy, approval, workflow, receipt, AI-agent, release verification, and
  checkpoint evidence records before runtime collection.
- [governance/EVIDENCE_PLANE.md](governance/EVIDENCE_PLANE.md): stable
  evidence plane entry point and validation gate.
- [adapters/GENERIC_EXTERNAL_EVENT_RECEIPT_ADAPTER.md](adapters/GENERIC_EXTERNAL_EVENT_RECEIPT_ADAPTER.md):
  M143 local-file import-only adapter for converting synthetic generic external
  events into Atlas receipts.
- [adapters/AI_AGENT_EVENT_RECEIPT_PROFILE.md](adapters/AI_AGENT_EVENT_RECEIPT_PROFILE.md):
  M146 metadata-only AI-agent event profile that treats agents as event
  sources, not authorities or execution engines.
- [reviews/GITHUB_ACTIONS_RUN_RECEIPT_CANDIDATE_M151.md](reviews/GITHUB_ACTIONS_RUN_RECEIPT_CANDIDATE_M151.md):
  M151 import-only GitHub Actions run/check event candidate using the existing
  generic external event adapter.
- [reviews/GITHUB_ACTIONS_EVENT_PROOF_PACKAGE_M153.md](reviews/GITHUB_ACTIONS_EVENT_PROOF_PACKAGE_M153.md):
  M153 reviewer-facing proof package for the GitHub Actions run/check receipt
  path and its M152 security boundary.
- [reviews/CONTROL_OBJECTIVE_MAPPING.md](reviews/CONTROL_OBJECTIVE_MAPPING.md):
  maps receipts, adapters, proof packages, and reviewer workflows to AI-agent
  governance, CI integrity, release governance, approval integrity, and audit
  readiness, production-readiness review, and business workflow assurance
  objectives.
- [reviews/PRODUCTION_READINESS_CONTROL_MAPPING_M156.md](reviews/PRODUCTION_READINESS_CONTROL_MAPPING_M156.md):
  maps the production-readiness contract to retained evidence, verification
  commands, positive support claims, and outside-Atlas determinations.
- [reviews/EVIDENCE_SUFFICIENCY_REPORT_M158.md](reviews/EVIDENCE_SUFFICIENCY_REPORT_M158.md):
  applies Trust Claim Ladder Level 4 to classify objective evidence as present,
  missing, stale, or unverifiable.
- [reviews/REVIEWER_DECISION_PACKET_M160.md](reviews/REVIEWER_DECISION_PACKET_M160.md):
  turns mapped objectives and evidence sufficiency status into a bounded decision path for reviewers.
- [reviews/REVIEWER_PLAIN_ENGLISH_OUTPUT_M166.md](reviews/REVIEWER_PLAIN_ENGLISH_OUTPUT_M166.md):
  translates receipts, replay, evidence sufficiency, and reviewer decisions
  into plain-English reader-mode output.
- [REVIEWER_QUICKSTART.md](REVIEWER_QUICKSTART.md): simplified reviewer
  quickstart with copy-paste commands, expected outputs, `prev_hash`
  explanation, and blocked-path guidance.
- [architecture/SCALE_AND_STORAGE_STRATEGY_M170.md](architecture/SCALE_AND_STORAGE_STRATEGY_M170.md):
  M170 scale/storage strategy for metadata-only receipts, generated indexes,
  archive rotation, future private collector boundaries, and future hosted
  verifier boundaries.
- [reviews/ADOPTION_FRICTION_DRY_RUN_M167.md](reviews/ADOPTION_FRICTION_DRY_RUN_M167.md):
  tests whether a new reviewer/operator can follow the CI release review path
  and understand the result without live explanation.
- [TRY_GENERIC_EVENT_ADAPTER.md](TRY_GENERIC_EVENT_ADAPTER.md): M145
  five-minute local quickstart for the generic external event adapter.
- [TRY_AI_AGENT_EVENT_RECEIPTS.md](TRY_AI_AGENT_EVENT_RECEIPTS.md): M147
  five-minute local quickstart for AI-agent event receipts and optional local
  model helper metadata.
- [governance/POLICY_PLANE.md](governance/POLICY_PLANE.md): stable policy
  plane entry point and validation gate.
- [governance/APPROVAL_PLANE.md](governance/APPROVAL_PLANE.md): stable
  approval plane entry point and validation gate.
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
- [TRUST_CLAIM_LADDER.md](TRUST_CLAIM_LADDER.md): positive claim ladder for
  translating Atlas proof records into bounded reviewer objectives.
- [reviews/CONTROL_OBJECTIVE_MAPPING.md](reviews/CONTROL_OBJECTIVE_MAPPING.md):
  control-objective mapping for AI-agent governance, CI integrity, release
  governance, production-readiness review, approval integrity, audit readiness,
  and business workflow assurance.
- [reviews/PRODUCTION_READINESS_CONTROL_MAPPING_M156.md](reviews/PRODUCTION_READINESS_CONTROL_MAPPING_M156.md):
  production-readiness control mapping for the local Atlas contract, release
  trust, artifact manifest, signing/provenance, production dry-run, reviewer
  package, and public export evidence.
- [reviews/EVIDENCE_SUFFICIENCY_REPORT_M158.md](reviews/EVIDENCE_SUFFICIENCY_REPORT_M158.md):
  evidence sufficiency report shape for mapped review objectives.
- [reviews/REVIEWER_DECISION_PACKET_M160.md](reviews/REVIEWER_DECISION_PACKET_M160.md):
  reviewer decision packet shape for objective, evidence status, verification
  path, limitations, and outside-Atlas determination.
- [reviews/REVIEWER_PLAIN_ENGLISH_OUTPUT_M166.md](reviews/REVIEWER_PLAIN_ENGLISH_OUTPUT_M166.md):
  plain-English output format for mixed technical and non-technical reviewers.
- [REVIEWER_QUICKSTART.md](REVIEWER_QUICKSTART.md): simplified reviewer path
  from first verify and replay to GitHub Actions metadata import and evidence
  sufficiency review.
- [workflows/ORG_CI_RELEASE_REVIEW_WORKFLOW_M164.md](workflows/ORG_CI_RELEASE_REVIEW_WORKFLOW_M164.md):
  adoption workflow for a bounded one-day CI release review using GitHub
  Actions metadata receipts and reviewer decision packet outcomes.
- [reviews/ADOPTION_FRICTION_DRY_RUN_M167.md](reviews/ADOPTION_FRICTION_DRY_RUN_M167.md):
  retained internal dry-run for adoption friction and reviewer clarity on the
  one-day CI release review path.
- [architecture/SCALE_AND_STORAGE_STRATEGY_M170.md](architecture/SCALE_AND_STORAGE_STRATEGY_M170.md):
  scale and storage strategy for larger metadata-only receipt volumes without
  adding runtime storage or weakening release-trust verification.
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
- [reviews/GITHUB_ACTIONS_EVENT_PROOF_PACKAGE_M153.md](reviews/GITHUB_ACTIONS_EVENT_PROOF_PACKAGE_M153.md):
  reviewer-facing proof package for the GitHub Actions run/check metadata
  receipt path.
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
- [reviews/PRODUCTION_READINESS_CONTROL_MAPPING_M156.md](reviews/PRODUCTION_READINESS_CONTROL_MAPPING_M156.md):
  reviewer-facing mapping from production-readiness gates to control
  objectives and outside-Atlas determinations.
- [reviews/EVIDENCE_SUFFICIENCY_REPORT_M158.md](reviews/EVIDENCE_SUFFICIENCY_REPORT_M158.md):
  reviewer-facing report for objective evidence sufficiency states.
- [reviews/REVIEWER_DECISION_PACKET_M160.md](reviews/REVIEWER_DECISION_PACKET_M160.md):
  reviewer-facing packet that turns evidence status into a bounded decision path without adding runtime behavior.
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
- [../CODE_OF_CONDUCT.md](../CODE_OF_CONDUCT.md): conduct expectations for the
  public trust and reviewer surface.
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
- [architecture/SCALE_AND_STORAGE_STRATEGY_M170.md](architecture/SCALE_AND_STORAGE_STRATEGY_M170.md):
  M170 architecture plan for receipt volume, file-backed truth, indexing,
  archive rotation, batch verification, batch replay, and future storage
  boundaries.
