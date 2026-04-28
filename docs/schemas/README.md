# Atlas Schema Contracts

## Purpose

This directory records stable Atlas JSON contract documentation for implemented
schema-versioned outputs.

These files are not generated JSON Schema documents yet. They are operational
schema contracts: required fields, allowed meanings, verification rules,
metadata-only boundaries, and non-goals.

The broader actor, object, packet, freshness, verification, and replay model is
documented at [../atlas/TRUST_OBJECT_MODEL.md](../atlas/TRUST_OBJECT_MODEL.md).

## Implemented Contracts

| Schema | Surface | Contract |
| --- | --- | --- |
| `atlas.release_trust.v1` | `atlas release packet --json` | [release-trust.v1.md](release-trust.v1.md) |
| `atlas.release_provenance.v1` | `docs/retention/releases/*.provenance.json` | [release-provenance.v1.md](release-provenance.v1.md) |
| `atlas.production_readiness.v1` | `atlas production status --json` | [production-readiness.v1.md](production-readiness.v1.md) |
| `atlas.operation_trust_chain.v1` | `atlas op trust-chain --json` | [operation-trust-chain.v1.md](operation-trust-chain.v1.md) |
| `atlas.handoff_packet.v1` | `atlas op handoff --json` | [handoff-packet.v1.md](handoff-packet.v1.md) |
| `atlas.closeout_manifest.v1` | `atlas op closeout --json` | [closeout-manifest.v1.md](closeout-manifest.v1.md) |
| `atlas.audit_packet.v1` | `atlas op audit-packet --json` | [audit-packet.v1.md](audit-packet.v1.md) |
| `atlas.archive_packet.v1` | `atlas op archive-packet --json` | [archive-packet.v1.md](archive-packet.v1.md) |
| `atlas.accepted_risk_review_packet.v1` | `atlas finding review-packet --json` | [accepted-risk-review-packet.v1.md](accepted-risk-review-packet.v1.md) |
| `atlas.advisor_prompt_packet.v1` | `atlas advisor prompt --json` | [advisor-prompt-packet.v1.md](advisor-prompt-packet.v1.md) |
| `atlas.business_flow_packet.v1` | `atlas flow packet --json` | [business-flow-packet.v1.md](business-flow-packet.v1.md) |
| `atlas.business_flow_verify.v1` | `atlas flow verify --json` | [business-flow-verify.v1.md](business-flow-verify.v1.md) |
| `atlas.business_flow_trust_chain.v1` | `atlas flow trust-chain --json` | [business-flow-trust-chain.v1.md](business-flow-trust-chain.v1.md) |

## Design Contracts

These contracts document optional modules and non-JSON packet surfaces. They
are not stable command outputs yet for JSON.

| Schema | Surface | Contract |
| --- | --- | --- |
| `atlas.business_flow.v1` | `state/atlas/flows/<flow-slug>.env` | [business-flow-record.v1.md](business-flow-record.v1.md) |
| `atlas.business_flow_link.v1` | `sessions/<operation>/business_flows.ndjson` | [business-flow-link.v1.md](business-flow-link.v1.md) |
| `atlas.flow_evidence_link.v1` | `sessions/<operation>/flow_evidence.ndjson` | [flow-evidence-link.v1.md](flow-evidence-link.v1.md) |
| `atlas.flow_finding_link.v1` | `sessions/<operation>/flow_findings.ndjson` | [flow-finding-link.v1.md](flow-finding-link.v1.md) |
| `atlas.flow_validation_link.v1` | `sessions/<operation>/flow_validation.ndjson` | [flow-validation-link.v1.md](flow-validation-link.v1.md) |
| `atlas.flow_approval_link.v1` | `sessions/<operation>/flow_approvals.ndjson` | [flow-approval-link.v1.md](flow-approval-link.v1.md) |
| `atlas.flow_retention_link.v1` | `sessions/<operation>/flow_retention.ndjson` | [flow-retention-link.v1.md](flow-retention-link.v1.md) |
| `atlas.business_flow_evidence.v1` | optional flow evidence object, JSON planned | [business-flow-evidence.v1.md](business-flow-evidence.v1.md) |

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
- `atlas release replay` validates `atlas.release_trust.v1` from a detached
  checkout of the packet commit.
- Release replay verification checks `atlas.release_trust.v1` against the
  packet's recorded commit from a clean checkout.
- `atlas production status` reports `atlas.production_readiness.v1` and
  verifies `atlas.release_provenance.v1` when signing/provenance is required.
