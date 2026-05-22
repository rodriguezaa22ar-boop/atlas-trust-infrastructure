# Atlas Trust Infrastructure

Atlas is metadata-first integrity infrastructure for operational proof.
It acts as a trust overlay for authorized work. It does not replace GitHub,
Nix, SSH, tmux, scanners, approval tools, or business systems.

It records and verifies the proof chain around them.

The chain answers:

- who requested the action
- what capability and policy applied
- whether approval was required
- what evidence and artifact references were emitted
- what commit or packet contains the result
- how another reviewer can replay the proof

## Public Repository Purpose

This public repository is the reviewer-facing trust surface for Atlas: safety
boundaries, governance contracts, release evidence, business-flow evidence, and
readiness language.

The private `atlas-lab-toolkit` repository remains the implementation home for
retained engineering context and operator runtime history. The public/private
boundary is defined in [docs/REPOSITORY_BOUNDARY.md](docs/REPOSITORY_BOUNDARY.md)
and enforced by `exports/public-trust-manifest.json`.

## Why Proof Chains, Not Just Logs?

Logs say something happened. Atlas proof chains bind intent, capability,
policy, approval metadata, evidence references, artifact hashes, commits, and
reviewer replay commands into a metadata-only record.

Atlas verifies that proof metadata is well-formed, linked, and replayable. It
does not grant permission, replace approval authorities, certify compliance, or
guarantee that an action was valid.

## Start Here

- New reader: [docs/ATLAS_ONE_PAGE.md](docs/ATLAS_ONE_PAGE.md); receipt RC: [docs/RECEIPT_OPEN_CORE_RC.md](docs/RECEIPT_OPEN_CORE_RC.md); quickstart: [docs/TRY_RECEIPTS.md](docs/TRY_RECEIPTS.md)
- Demo path: [docs/demo/DEMO_OPERATION.md](docs/demo/DEMO_OPERATION.md) and [docs/demo/DEMO_REVIEWER_RUNBOOK.md](docs/demo/DEMO_REVIEWER_RUNBOOK.md)
- Security operator: [docs/OPERATOR_GUIDE.md](docs/OPERATOR_GUIDE.md)
- Release reviewer: [docs/RELEASE_TRUST.md](docs/RELEASE_TRUST.md)
- SLSA reviewer: [docs/atlas/SLSA_CLAIM.md](docs/atlas/SLSA_CLAIM.md)
- Business owner: [docs/atlas/BUSINESS_FLOW_EVIDENCE.md](docs/atlas/BUSINESS_FLOW_EVIDENCE.md)
- Governance reader: [docs/governance/CAPABILITY_MODEL.md](docs/governance/CAPABILITY_MODEL.md)
- Contributor: [CONTRIBUTING.md](CONTRIBUTING.md)
- Security reporter: [SECURITY.md](SECURITY.md)

The demo uses synthetic/local-safe data only. It shows a metadata-only
operation, evidence and finding links, approval references, retained packets,
and reviewer verification without storing raw runtime evidence.

## Quick Start

Run from the repository root:

```bash
nix-shell
./bin/labctl status
./tools/atlas/bin/atlas doctor
./tools/atlas/bin/atlas v1 status --strict
./tools/atlas/bin/atlas production status --strict
```

Full local QA: `nix-shell --run './bin/dev-qa'`

## Safety Boundary

Atlas is for authorized assessment orchestration only.

Do not use it for autonomous exploitation, persistence, destructive testing,
credential spraying, denial-of-service workflows, stealth/evasion behavior, or
out-of-scope target expansion. Target-touching workflows should preserve scope
checks, capability classification, operator intent, approval gates where
required, ledger events, and evidence handling.

Atlas does not claim external audit, enterprise certification, external SLSA
certification, deployment certification, immutable storage, tamper-proof
infrastructure, runtime safety, or compliance approval.
This is not external SLSA certification.

## Current Maturity

Atlas can report `production-ready under the local Atlas contract` when v1
readiness is clean, the repository is synced, release packets verify, artifact
manifests verify, signing/provenance verifies, and production dry-run evidence
is retained for the current release commit.

Atlas has a SLSA-verifiable release artifact candidate path for GitHub-built
artifacts: GitHub-hosted artifact attestation, official SLSA generic provenance,
retained Atlas metadata, and verifier commands.

CodeQL is used as an automated code scanning signal for tracked public source.
It does not replace manual review, external audit, runtime testing, or Atlas'
own retained trust-packet verification.

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
| [docs/INDEX.md](docs/INDEX.md) / [docs/REPOSITORY_BOUNDARY.md](docs/REPOSITORY_BOUNDARY.md) | Documentation map and public/private boundary. |
| [docs/ATLAS_ONE_PAGE.md](docs/ATLAS_ONE_PAGE.md) | One-page Atlas explanation. |
| [docs/OPERATOR_GUIDE.md](docs/OPERATOR_GUIDE.md) / [docs/ops/DUAL_NODE_COCKPIT.md](docs/ops/DUAL_NODE_COCKPIT.md) / [docs/ops/PORTABILITY_CONTRACT.md](docs/ops/PORTABILITY_CONTRACT.md) | Operator workflow, dual-node cockpit, and portability contract. |
| [docs/demo/DEMO_OPERATION.md](docs/demo/DEMO_OPERATION.md) | Synthetic metadata-only demo operation. |
| [docs/COMMAND_REFERENCE.md](docs/COMMAND_REFERENCE.md) | Full command reference moved out of the README. |
| [docs/TRUST_LIFECYCLE.md](docs/TRUST_LIFECYCLE.md) | Scope-to-release trust chain explanation. |
| [docs/case-studies/CASE_STUDY_RELEASE_TRUST.md](docs/case-studies/CASE_STUDY_RELEASE_TRUST.md) / [docs/case-studies/CASE_STUDY_VENDOR_PAYMENT_CHANGE.md](docs/case-studies/CASE_STUDY_VENDOR_PAYMENT_CHANGE.md) | Release-trust and business-flow case studies. |
| [docs/atlas/TRUST_INFRASTRUCTURE_DIRECTION.md](docs/atlas/TRUST_INFRASTRUCTURE_DIRECTION.md) / [docs/atlas/TRUST_OBJECT_MODEL.md](docs/atlas/TRUST_OBJECT_MODEL.md) | Atlas direction, objects, packets, freshness, verification, and replay. |
| [docs/governance/CAPABILITY_MODEL.md](docs/governance/CAPABILITY_MODEL.md) / [docs/governance/ADAPTER_REGISTRY.md](docs/governance/ADAPTER_REGISTRY.md) / [docs/governance/POLICY_PLANE.md](docs/governance/POLICY_PLANE.md) / [docs/governance/APPROVAL_PLANE.md](docs/governance/APPROVAL_PLANE.md) | Capabilities, adapters, policy, and approvals. |
| [docs/RELEASE_TRUST.md](docs/RELEASE_TRUST.md) / [docs/atlas/RELEASE_ARTIFACT_MANIFEST.md](docs/atlas/RELEASE_ARTIFACT_MANIFEST.md) | Release packets, artifact manifests, verification, replay, signing, and provenance. |
| [docs/atlas/SLSA_PROVENANCE.md](docs/atlas/SLSA_PROVENANCE.md) / [docs/atlas/SLSA_CLAIM.md](docs/atlas/SLSA_CLAIM.md) | GitHub/Sigstore SLSA provenance workflow and bounded claim. |
| [docs/atlas/V1_INTERNAL_RC.md](docs/atlas/V1_INTERNAL_RC.md) / [docs/atlas/V1_PILLAR_READINESS.md](docs/atlas/V1_PILLAR_READINESS.md) / [docs/atlas/PRODUCTION_READINESS.md](docs/atlas/PRODUCTION_READINESS.md) | Atlas v1 Internal Release Candidate scope, pillar readiness, and local production readiness contract. |
| [docs/WEB_ASSESSMENT.md](docs/WEB_ASSESSMENT.md) / [docs/atlas/BUSINESS_FLOW_EVIDENCE.md](docs/atlas/BUSINESS_FLOW_EVIDENCE.md) | Web assessment and optional metadata-only business-flow evidence. |
| [docs/TRUST_MODEL.md](docs/TRUST_MODEL.md) / [docs/SECURITY_MODEL.md](docs/SECURITY_MODEL.md) / [docs/RESPONSIBLE_USE.md](docs/RESPONSIBLE_USE.md) / [docs/KNOWN_LIMITATIONS.md](docs/KNOWN_LIMITATIONS.md) | Trust, security, responsible-use, and limitation boundaries. |
| [docs/CI.md](docs/CI.md) / [SECURITY.md](SECURITY.md) / [CONTRIBUTING.md](CONTRIBUTING.md) | CI parity, vulnerability reporting, and contribution rules. |

## Development

The development shell provides the expected local toolchain, including `bats`,
`git`, `gpg`, `jq`, `rg`, `shellcheck`, and `shfmt`.

Common development gates:

```bash
./bin/dev-fmt
./bin/dev-lint
./bin/dev-test
./bin/dev-stress
./bin/dev-qa
```

Before treating a change as complete, run the strongest relevant gate and keep
the repo clean and synced.
