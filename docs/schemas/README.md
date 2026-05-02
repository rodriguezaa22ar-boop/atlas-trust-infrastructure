# Atlas Schema Contracts

## Purpose

This directory records stable Atlas JSON contract documentation for implemented
schema-versioned outputs.

These files are not generated JSON Schema documents yet. They are operational
schema contracts: required fields, allowed meanings, verification rules,
metadata-only boundaries, and non-goals.

The broader actor, object, packet, freshness, verification, and replay model is
documented at [../atlas/TRUST_OBJECT_MODEL.md](../atlas/TRUST_OBJECT_MODEL.md).

## Freeze Candidate

M120 classifies current schema contracts in
[SCHEMA_FREEZE_CANDIDATE.md](SCHEMA_FREEZE_CANDIDATE.md). After that
milestone, field renames, field removals, type changes, required-field changes,
status enum meaning changes, verification semantic changes, or metadata-only
boundary weakening require a version bump.

Backward-compatible optional additions may be allowed without a version bump
only when documented in the affected schema contract and in the freeze
candidate record.

## Classification Summary

| Classification | Meaning |
| --- | --- |
| stable | Core v1 trust surface implemented and tested for internal RC review. |
| optional | Implemented or documented optional module; not required for core v1 or production readiness. |
| experimental | Implemented but not v1-stable enough for reliance. |
| future | Planned or directional only. |
| retained-only | Stable retained metadata evidence contract reviewed through retained files and verification commands. |

## Implemented Contracts

| Classification | Schema | Surface | Contract |
| --- | --- | --- | --- |
| stable | `atlas.release_trust.v1` | `atlas release packet --json` | [release-trust.v1.md](release-trust.v1.md) |
| stable | `atlas.release_replay.v1` | `atlas release replay --json` | [release-replay.v1.md](release-replay.v1.md) |
| retained-only | `atlas.release_provenance.v1` | `docs/retention/releases/*.provenance.json` | [release-provenance.v1.md](release-provenance.v1.md) |
| stable | `atlas.release_artifact_manifest.v1` | `atlas release manifest` | [release-artifact-manifest.v1.md](release-artifact-manifest.v1.md) |
| stable | `atlas.external_reviewer_package.v1` | `atlas reviewer package` | [external-reviewer-package.v1.md](external-reviewer-package.v1.md) |
| retained-only | `atlas.slsa_provenance.v1` | `.github/workflows/release-slsa.yml`, `.github/workflows/release-slsa-generic.yml`, GitHub Artifact Attestations, and official SLSA generic provenance | [slsa-provenance.v1.md](slsa-provenance.v1.md) |
| stable | `atlas.production_readiness.v1` | `atlas production status --json` | [production-readiness.v1.md](production-readiness.v1.md) |
| stable | `atlas.operation_trust_chain.v1` | `atlas op trust-chain --json` | [operation-trust-chain.v1.md](operation-trust-chain.v1.md) |
| stable | `atlas.handoff_packet.v1` | `atlas op handoff --json` | [handoff-packet.v1.md](handoff-packet.v1.md) |
| stable | `atlas.closeout_manifest.v1` | `atlas op closeout --json` | [closeout-manifest.v1.md](closeout-manifest.v1.md) |
| stable | `atlas.audit_packet.v1` | `atlas op audit-packet --json` | [audit-packet.v1.md](audit-packet.v1.md) |
| stable | `atlas.archive_packet.v1` | `atlas op archive-packet --json` | [archive-packet.v1.md](archive-packet.v1.md) |
| stable | `atlas.accepted_risk_review_packet.v1` | `atlas finding review-packet --json` | [accepted-risk-review-packet.v1.md](accepted-risk-review-packet.v1.md) |
| optional | `atlas.advisor_prompt_packet.v1` | `atlas advisor prompt --json` | [advisor-prompt-packet.v1.md](advisor-prompt-packet.v1.md) |
| optional | `atlas.business_flow_packet.v1` | `atlas flow packet --json` | [business-flow-packet.v1.md](business-flow-packet.v1.md) |
| optional | `atlas.business_flow_verify.v1` | `atlas flow verify --json` | [business-flow-verify.v1.md](business-flow-verify.v1.md) |
| optional | `atlas.business_flow_assurance.v1` | `atlas flow assurance --json` | [business-flow-assurance.v1.md](business-flow-assurance.v1.md) |
| optional | `atlas.business_flow_trust_chain.v1` | `atlas flow trust-chain --json` | [business-flow-trust-chain.v1.md](business-flow-trust-chain.v1.md) |

## Design Contracts

These contracts document optional modules and non-JSON packet surfaces. They
are not stable command outputs yet for JSON.

| Classification | Schema | Surface | Contract |
| --- | --- | --- | --- |
| optional | `atlas.business_flow.v1` | `state/atlas/flows/<flow-slug>.env` | [business-flow-record.v1.md](business-flow-record.v1.md) |
| optional | `atlas.business_flow_link.v1` | `sessions/<operation>/business_flows.ndjson` | [business-flow-link.v1.md](business-flow-link.v1.md) |
| optional | `atlas.flow_evidence_link.v1` | `sessions/<operation>/flow_evidence.ndjson` | [flow-evidence-link.v1.md](flow-evidence-link.v1.md) |
| optional | `atlas.flow_finding_link.v1` | `sessions/<operation>/flow_findings.ndjson` | [flow-finding-link.v1.md](flow-finding-link.v1.md) |
| optional | `atlas.flow_validation_link.v1` | `sessions/<operation>/flow_validation.ndjson` | [flow-validation-link.v1.md](flow-validation-link.v1.md) |
| optional | `atlas.flow_approval_link.v1` | `sessions/<operation>/flow_approvals.ndjson` | [flow-approval-link.v1.md](flow-approval-link.v1.md) |
| optional | `atlas.flow_retention_link.v1` | `sessions/<operation>/flow_retention.ndjson` | [flow-retention-link.v1.md](flow-retention-link.v1.md) |
| optional | `atlas.business_flow_evidence.v1` | optional flow evidence object, JSON planned | [business-flow-evidence.v1.md](business-flow-evidence.v1.md) |

## Rules

- Every schema-versioned Atlas JSON output must be documented here.
- Every documented schema must name required fields and verification rules.
- Packet-oriented schemas must remain metadata-only.
- Design contracts must clearly distinguish implemented Markdown behavior from
  planned JSON behavior until a stable JSON command emits them.
- Future JSON packet formats should be added here before being treated as
  stable release or replay inputs.

## Release Trust Consumers

- `atlas release verify` validates `atlas.release_trust.v1`.
- `atlas release replay` validates `atlas.release_trust.v1` from an isolated
  checkout of the packet commit.
- Release replay verification can be reported with `atlas release replay
  --json` as `atlas.release_replay.v1`, recording metadata-only replay check
  statuses without embedding QA logs or raw runtime artifacts.
- `atlas release manifest-verify` validates
  `atlas.release_artifact_manifest.v1` by checking retained artifact hashes,
  required artifact classes, required paths, schema references, release packet
  verification, signed provenance, the retained public key, the production
  dry-run note, and forbidden raw-content markers.
- `atlas release slsa-verify` validates retained
  `atlas.slsa_provenance.v1` references by checking schema, metadata-only
  flags, forbidden-content markers, source commit, artifact digest, workflow
  path, GitHub run URL, recorded attestation verification status, and known
  limitations. With `--artifact`, it checks the downloaded artifact's SHA-256;
  with `--online`, it runs `gh attestation verify`.
- `atlas reviewer package` emits `atlas.external_reviewer_package.v1` and
  verifies the latest release packet, release artifact manifest, signed
  provenance, production dry-run note, and retained milestone note before
  building a metadata-only external review bundle.
- `atlas production status` reports `atlas.production_readiness.v1` and
  verifies `atlas.release_artifact_manifest.v1` and
  `atlas.release_provenance.v1` when production trust evidence is required.
- `.github/workflows/release-slsa.yml` prepares release artifacts for
  GitHub/Sigstore SLSA provenance verification. Atlas does not treat that as
  external SLSA certification.
- `.github/workflows/release-slsa-generic.yml` prepares release artifacts for
  official `slsa-framework/slsa-github-generator` generic provenance. Atlas
  does not treat that as external SLSA certification.
