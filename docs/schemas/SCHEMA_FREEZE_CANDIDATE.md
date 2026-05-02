# Trust Schema Freeze Candidate

## Purpose

This document classifies the current Atlas trust schemas as v1 freeze
candidates before Atlas v1 Internal RC.

Freeze candidate does not mean permanent immutability. It means the listed
contracts are stable enough for internal v1 review and future changes must
follow versioning discipline.

## Classification Meanings

- `stable`: implemented and tested as part of the core v1 trust surface.
- `optional`: implemented or documented for an optional module that is not
  required for core v1 or production readiness.
- `experimental`: implemented but intentionally not stable enough for v1
  reliance.
- `future`: planned or directional only.
- `retained-only`: retained metadata evidence contract, usually written under
  `docs/retention/`, not a live command-status surface.

No current v1 freeze-candidate schema is classified as `experimental` or
`future`. Future schemas must be added with one of those labels until a
stable command or retained-evidence path exists.

## Freeze Rule

After M120, no schema field rename, removal, type change, required-field
change, status enum meaning change, or verification semantic change should
land without a version bump.

Allowed without a version bump:

- documentation clarification
- typo fixes
- non-semantic examples
- backward-compatible optional fields when documented in this file and in the
  schema contract

Requires a version bump:

- required field addition, removal, or rename
- field type change
- field meaning change
- enum value removal or enum meaning change
- required field change
- verification semantic change
- metadata-only boundary weakening
- changing an optional module into a required production gate

## Core V1 Stable Schemas

These schemas are part of the core Atlas v1 trust surface.

| Classification | Schema | Contract | Surface |
| --- | --- | --- | --- |
| stable | `atlas.release_trust.v1` | [release-trust.v1.md](release-trust.v1.md) | `atlas release packet --json` |
| stable | `atlas.release_replay.v1` | [release-replay.v1.md](release-replay.v1.md) | `atlas release replay --json` |
| stable | `atlas.release_artifact_manifest.v1` | [release-artifact-manifest.v1.md](release-artifact-manifest.v1.md) | `atlas release manifest` |
| stable | `atlas.production_readiness.v1` | [production-readiness.v1.md](production-readiness.v1.md) | `atlas production status --json` |
| stable | `atlas.operation_trust_chain.v1` | [operation-trust-chain.v1.md](operation-trust-chain.v1.md) | `atlas op trust-chain --json` |
| stable | `atlas.handoff_packet.v1` | [handoff-packet.v1.md](handoff-packet.v1.md) | `atlas op handoff --json` |
| stable | `atlas.closeout_manifest.v1` | [closeout-manifest.v1.md](closeout-manifest.v1.md) | `atlas op closeout --json` |
| stable | `atlas.audit_packet.v1` | [audit-packet.v1.md](audit-packet.v1.md) | `atlas op audit-packet --json` |
| stable | `atlas.archive_packet.v1` | [archive-packet.v1.md](archive-packet.v1.md) | `atlas op archive-packet --json` |
| stable | `atlas.accepted_risk_review_packet.v1` | [accepted-risk-review-packet.v1.md](accepted-risk-review-packet.v1.md) | `atlas finding review-packet --json` |
| stable | `atlas.external_reviewer_package.v1` | [external-reviewer-package.v1.md](external-reviewer-package.v1.md) | `atlas reviewer package` |

## Retained-Only Schemas

These schemas are stable retained evidence contracts. They are expected to be
reviewed through retained files and verification commands rather than treated
as general live command status outputs.

| Classification | Schema | Contract | Surface |
| --- | --- | --- | --- |
| retained-only | `atlas.release_provenance.v1` | [release-provenance.v1.md](release-provenance.v1.md) | `docs/retention/releases/*.provenance.json` |
| retained-only | `atlas.slsa_provenance.v1` | [slsa-provenance.v1.md](slsa-provenance.v1.md) | retained SLSA-verifiable artifact candidate metadata |

## Optional Module Schemas

These schemas are implemented or documented for optional surfaces. They remain
metadata-only and reviewable, but they are not required for core v1 readiness
or production readiness.

| Classification | Schema | Contract | Surface |
| --- | --- | --- | --- |
| optional | `atlas.advisor_prompt_packet.v1` | [advisor-prompt-packet.v1.md](advisor-prompt-packet.v1.md) | `atlas advisor prompt --json` |
| optional | `atlas.business_flow.v1` | [business-flow-record.v1.md](business-flow-record.v1.md) | `state/atlas/flows/<flow-slug>.env` |
| optional | `atlas.business_flow_link.v1` | [business-flow-link.v1.md](business-flow-link.v1.md) | `sessions/<operation>/business_flows.ndjson` |
| optional | `atlas.flow_evidence_link.v1` | [flow-evidence-link.v1.md](flow-evidence-link.v1.md) | `sessions/<operation>/flow_evidence.ndjson` |
| optional | `atlas.flow_finding_link.v1` | [flow-finding-link.v1.md](flow-finding-link.v1.md) | `sessions/<operation>/flow_findings.ndjson` |
| optional | `atlas.flow_validation_link.v1` | [flow-validation-link.v1.md](flow-validation-link.v1.md) | `sessions/<operation>/flow_validation.ndjson` |
| optional | `atlas.flow_approval_link.v1` | [flow-approval-link.v1.md](flow-approval-link.v1.md) | `sessions/<operation>/flow_approvals.ndjson` |
| optional | `atlas.flow_retention_link.v1` | [flow-retention-link.v1.md](flow-retention-link.v1.md) | `sessions/<operation>/flow_retention.ndjson` |
| optional | `atlas.business_flow_evidence.v1` | [business-flow-evidence.v1.md](business-flow-evidence.v1.md) | optional aggregate Business Flow Evidence object |
| optional | `atlas.business_flow_packet.v1` | [business-flow-packet.v1.md](business-flow-packet.v1.md) | `atlas flow packet --json` |
| optional | `atlas.business_flow_verify.v1` | [business-flow-verify.v1.md](business-flow-verify.v1.md) | `atlas flow verify --json` |
| optional | `atlas.business_flow_assurance.v1` | [business-flow-assurance.v1.md](business-flow-assurance.v1.md) | `atlas flow assurance --json` |
| optional | `atlas.business_flow_trust_chain.v1` | [business-flow-trust-chain.v1.md](business-flow-trust-chain.v1.md) | `atlas flow trust-chain --json` |

## Module Boundary

Core release trust schemas support v1 readiness, retained release packet
verification, release artifact manifest verification, release replay JSON,
production status JSON, production explainability, and reviewer packages.

Business Flow Evidence schemas remain optional-ready. They can strengthen a
review, link business flows to operation proof, and appear as non-blocking
readiness context, but they are not core-required production gates.

SLSA provenance schemas describe a SLSA-verifiable release artifact candidate
path and retained Atlas metadata references. They do not claim external SLSA
certification.

Demo docs are not schemas.

## Metadata-Only Boundary

All packet and trust schemas must preserve the metadata-only boundary. Atlas
schemas may store IDs, paths, hashes, timestamps, counts, statuses, command
names, commit IDs, tag names, workflow identities, verification states, and
known limitations.

Atlas schemas must not embed secrets, credentials, tokens, private keys,
session cookies, raw target data, raw customer data, payment data, bank
details, packet captures, full request or response bodies, raw runtime
artifacts, unredacted evidence bodies, raw invoices, raw contracts, exploit
payloads, or unauthorized-access instructions.

## Non-Guarantees

The schema freeze candidate is:

- not external audit
- not certification
- not legal compliance
- not tamper-proof infrastructure
- not external SLSA certification
- not runtime safety proof
- not production deployability proof

## Known Limitations

- These files are operational schema contracts, not generated JSON Schema
  documents.
- Freeze candidate status is for internal v1 review, not third-party
  certification.
- Optional module contracts may remain optional even if they are stable enough
  for review.
- Retained-only schemas depend on Git history, retained files, hashes, and
  local verification commands.
