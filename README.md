# Atlas Trust Infrastructure

Atlas is metadata-first integrity infrastructure for operational proof. It supports audit-ready evidence, release governance, CI integrity review, AI-agent action review, approval integrity, evidence sufficiency, and reviewer decision support. It acts as a trust overlay for authorized work around GitHub, Nix, SSH, tmux, scanners, approval tools, and business systems. It records and verifies the proof chain around them.

The chain records who requested an action, what capability and policy applied,
whether approval was required, which evidence and artifact references were
emitted, what commit or packet contains the result, and how a reviewer can
replay the proof.

## Public Repository Purpose

This public repository is the reviewer-facing trust surface for Atlas: safety boundaries, governance contracts, release evidence, business-flow evidence, and readiness language. The private `atlas-lab-toolkit` repository remains the implementation home for retained engineering context and operator runtime history. See [docs/REPOSITORY_BOUNDARY.md](docs/REPOSITORY_BOUNDARY.md) and `exports/public-trust-manifest.json`.

## Why Proof Chains, Not Just Logs?

Logs say something happened. Atlas proof chains bind intent, capability, policy, approval metadata, evidence references, artifact hashes, commits, and reviewer replay commands into a metadata-only record. Atlas verifies that proof metadata is well-formed, linked, and replayable.

Atlas records and verifies metadata-only proof chains. It does not grant
permission, replace approval authorities, certify compliance, prove legal
sufficiency, guarantee action validity, prove complete event coverage, or
replace human judgment. Atlas does not grant permission by itself.

Atlas proof records must not embed raw logs, secrets, private keys, tokens, Authorization headers, request bodies, response bodies, packet captures, raw prompts, raw model outputs, tool output bodies, browser/session/cookie material, customer data, payment data, private business records, unredacted evidence bodies, or raw artifacts.

## Current Direction

Atlas is becoming open proof infrastructure for critical digital actions. The
current public governance stack is:

```text
capability -> adapter -> policy -> approval -> evidence -> decision vocabulary
```

These layers are public governance contracts, draft schemas, examples, and
validation surfaces unless runtime implementation is explicitly added later.
The bounded value is clearer review, fewer ambiguous decisions, lower evidence
reconstruction work, privacy-preserving governance, stronger audit readiness,
lower cost of trust without lowering standards, and proof without exposure.

## Billion-Dollar Direction, Bounded

Atlas can grow into global proof infrastructure without becoming the raw-data warehouse or replacing the systems it reviews. Product directions remain future direction unless listed as implemented elsewhere: Atlas Open Core, Atlas Enterprise, Atlas Verify, Atlas Connectors, Atlas Review, Atlas Policy, and Atlas Evidence Lake. This direction does not claim compliance, certification, external audit completion, tamper-proof infrastructure, immutable storage, complete event coverage, proof that actions outside Atlas did not happen, runtime safety, model correctness, artifact correctness, or replacement of human judgment.

## Start Here

- New reader: [docs/ATLAS_ONE_PAGE.md](docs/ATLAS_ONE_PAGE.md); public trust surface: [docs/PUBLIC_TRUST_SURFACE.md](docs/PUBLIC_TRUST_SURFACE.md); receipt RC: [docs/RECEIPT_OPEN_CORE_RC.md](docs/RECEIPT_OPEN_CORE_RC.md); quickstarts: [docs/TRY_RECEIPTS.md](docs/TRY_RECEIPTS.md), [docs/TRY_GENERIC_EVENT_ADAPTER.md](docs/TRY_GENERIC_EVENT_ADAPTER.md), [docs/TRY_AI_AGENT_EVENT_RECEIPTS.md](docs/TRY_AI_AGENT_EVENT_RECEIPTS.md)
- Demo path: [docs/demo/DEMO_OPERATION.md](docs/demo/DEMO_OPERATION.md) and [docs/demo/DEMO_REVIEWER_RUNBOOK.md](docs/demo/DEMO_REVIEWER_RUNBOOK.md)
- Security operator: [docs/OPERATOR_GUIDE.md](docs/OPERATOR_GUIDE.md)
- Release reviewer: [docs/RELEASE_TRUST.md](docs/RELEASE_TRUST.md)
- SLSA reviewer: [docs/atlas/SLSA_CLAIM.md](docs/atlas/SLSA_CLAIM.md)
- Business owner: [docs/atlas/BUSINESS_FLOW_EVIDENCE.md](docs/atlas/BUSINESS_FLOW_EVIDENCE.md)
- Governance reader: [docs/governance/CAPABILITY_MODEL.md](docs/governance/CAPABILITY_MODEL.md), [docs/governance/CAPABILITY_MANIFEST_M172.md](docs/governance/CAPABILITY_MANIFEST_M172.md), [docs/governance/ADAPTER_REGISTRY.md](docs/governance/ADAPTER_REGISTRY.md), [docs/governance/ADAPTER_REGISTRY_M174.md](docs/governance/ADAPTER_REGISTRY_M174.md), [docs/governance/POLICY_PLANE.md](docs/governance/POLICY_PLANE.md), [docs/governance/POLICY_PLANE_M176.md](docs/governance/POLICY_PLANE_M176.md), [docs/governance/APPROVAL_PLANE.md](docs/governance/APPROVAL_PLANE.md), [docs/governance/APPROVAL_PLANE_M178.md](docs/governance/APPROVAL_PLANE_M178.md), [docs/governance/EVIDENCE_ENVELOPE_SCHEMA_M180.md](docs/governance/EVIDENCE_ENVELOPE_SCHEMA_M180.md), [docs/governance/GOVERNANCE_PLANE_INTEGRATION_MAP_M182.md](docs/governance/GOVERNANCE_PLANE_INTEGRATION_MAP_M182.md), and [docs/governance/GOVERNANCE_DECISION_VOCABULARY_M184.md](docs/governance/GOVERNANCE_DECISION_VOCABULARY_M184.md)
- Contributor: [CONTRIBUTING.md](CONTRIBUTING.md); security reporter: [SECURITY.md](SECURITY.md)

The demo uses synthetic/local-safe data only. It shows metadata-only operation, evidence and finding links, approvals, retained packets, and reviewer verification without raw runtime evidence.

## Quick Start

```bash
nix-shell
./bin/labctl status
./tools/atlas/bin/atlas doctor
./tools/atlas/bin/atlas v1 status --strict
./tools/atlas/bin/atlas production status --strict
```

Full local QA: `nix-shell --run './bin/dev-qa'`

## Safety Boundary

Atlas is for authorized assessment orchestration only. Do not use it for
autonomous exploitation, persistence, destructive testing, credential spraying,
denial-of-service workflows, stealth/evasion behavior, or out-of-scope target
expansion. Target-touching workflows should preserve scope checks, capability
classification, operator intent, approval gates where required, ledger events,
and evidence handling.

Atlas does not claim external audit, enterprise certification, deployment
certification, immutable storage, tamper-proof infrastructure, runtime safety,
or compliance approval. This is not external SLSA certification.

## Current Maturity

Atlas is in an internal engineering and trust-hardening phase. Local readiness
commands can report that the internal Atlas contract passes for retained
evidence; do not read `production-ready under the local Atlas contract` as
external production certification, legal sufficiency, or deployment approval.
See [docs/atlas/V1_INTERNAL_RC.md](docs/atlas/V1_INTERNAL_RC.md) for the Atlas v1 Internal Release Candidate scope.

Atlas has a SLSA-verifiable release artifact candidate path for GitHub-built artifacts: GitHub-hosted artifact attestation, official SLSA generic provenance, retained Atlas metadata, and verifier commands.

CodeQL is used as an automated code scanning signal for tracked public source. It does not replace manual review, external audit, runtime testing, or Atlas' own retained trust-packet verification.

## Top 10 Commands

```bash
./bin/labctl status
./tools/atlas/bin/atlas doctor
./tools/atlas/bin/atlas v1 status --strict
./tools/atlas/bin/atlas production status --strict
./tools/atlas/bin/atlas target update <target> --scope-status in-scope
./tools/atlas/bin/atlas op start --profile <profile> <operation> <target> <notes...>
./tools/atlas/bin/atlas web assess <url> <assessment-name> --scope-status in-scope
./tools/atlas/bin/atlas op trust-chain <operation> --strict
./tools/atlas/bin/atlas release packet <name> --json --qa-status pass
./tools/atlas/bin/atlas release verify <name>
```

## Docs Map

| Start Here | Purpose |
| --- | --- |
| [docs/INDEX.md](docs/INDEX.md) / [docs/REPOSITORY_BOUNDARY.md](docs/REPOSITORY_BOUNDARY.md) / [docs/ATLAS_ONE_PAGE.md](docs/ATLAS_ONE_PAGE.md) / [docs/COMMAND_REFERENCE.md](docs/COMMAND_REFERENCE.md) | Documentation map, public/private boundary, one-page explanation, and command reference. |
| [docs/TRUST_LIFECYCLE.md](docs/TRUST_LIFECYCLE.md) / [docs/atlas/TRUST_INFRASTRUCTURE_DIRECTION.md](docs/atlas/TRUST_INFRASTRUCTURE_DIRECTION.md) / [docs/atlas/TRUST_OBJECT_MODEL.md](docs/atlas/TRUST_OBJECT_MODEL.md) | Trust lifecycle, direction, objects, packets, freshness, verification, and replay. |
| [docs/OPERATOR_GUIDE.md](docs/OPERATOR_GUIDE.md) / [docs/ops/DUAL_NODE_COCKPIT.md](docs/ops/DUAL_NODE_COCKPIT.md) / [docs/ops/PORTABILITY_CONTRACT.md](docs/ops/PORTABILITY_CONTRACT.md) / [docs/demo/DEMO_OPERATION.md](docs/demo/DEMO_OPERATION.md) | Operator workflow, dual-node cockpit, portability, and synthetic demo. |
| [docs/case-studies/CASE_STUDY_RELEASE_TRUST.md](docs/case-studies/CASE_STUDY_RELEASE_TRUST.md) / [docs/case-studies/CASE_STUDY_VENDOR_PAYMENT_CHANGE.md](docs/case-studies/CASE_STUDY_VENDOR_PAYMENT_CHANGE.md) / [docs/WEB_ASSESSMENT.md](docs/WEB_ASSESSMENT.md) / [docs/atlas/BUSINESS_FLOW_EVIDENCE.md](docs/atlas/BUSINESS_FLOW_EVIDENCE.md) | Case studies, web assessment, and metadata-only business-flow evidence. |
| [docs/governance/CAPABILITY_MODEL.md](docs/governance/CAPABILITY_MODEL.md) / [docs/governance/ADAPTER_REGISTRY.md](docs/governance/ADAPTER_REGISTRY.md) / [docs/governance/POLICY_PLANE.md](docs/governance/POLICY_PLANE.md) / [docs/governance/APPROVAL_PLANE.md](docs/governance/APPROVAL_PLANE.md) | Stable governance entry points. |
| [docs/governance/CAPABILITY_MANIFEST_M172.md](docs/governance/CAPABILITY_MANIFEST_M172.md) / [docs/governance/ADAPTER_REGISTRY_M174.md](docs/governance/ADAPTER_REGISTRY_M174.md) / [docs/governance/POLICY_PLANE_M176.md](docs/governance/POLICY_PLANE_M176.md) / [docs/governance/APPROVAL_PLANE_M178.md](docs/governance/APPROVAL_PLANE_M178.md) / [docs/governance/EVIDENCE_ENVELOPE_SCHEMA_M180.md](docs/governance/EVIDENCE_ENVELOPE_SCHEMA_M180.md) / [docs/governance/GOVERNANCE_PLANE_INTEGRATION_MAP_M182.md](docs/governance/GOVERNANCE_PLANE_INTEGRATION_MAP_M182.md) / [docs/governance/GOVERNANCE_DECISION_VOCABULARY_M184.md](docs/governance/GOVERNANCE_DECISION_VOCABULARY_M184.md) | Current governance stack: capability, adapter, policy, approval, evidence, integration map, and decision vocabulary. |
| [docs/RELEASE_TRUST.md](docs/RELEASE_TRUST.md) / [docs/atlas/RELEASE_ARTIFACT_MANIFEST.md](docs/atlas/RELEASE_ARTIFACT_MANIFEST.md) / [docs/atlas/SLSA_PROVENANCE.md](docs/atlas/SLSA_PROVENANCE.md) / [docs/atlas/SLSA_CLAIM.md](docs/atlas/SLSA_CLAIM.md) | Release packets, artifact manifests, SLSA provenance workflow, and bounded claim. |
| [docs/TRUST_MODEL.md](docs/TRUST_MODEL.md) / [docs/SECURITY_MODEL.md](docs/SECURITY_MODEL.md) / [docs/RESPONSIBLE_USE.md](docs/RESPONSIBLE_USE.md) / [docs/KNOWN_LIMITATIONS.md](docs/KNOWN_LIMITATIONS.md) / [docs/CI.md](docs/CI.md) / [CONTRIBUTING.md](CONTRIBUTING.md) | Trust, security, responsible use, known limitations, CI parity, and contribution rules. |

## Development

Common gates: `./bin/dev-governance`, `./bin/dev-decisions`, and `nix-shell --run './bin/dev-qa'`. Keep the repo clean and synced before treating a change as complete.
