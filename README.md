# Atlas Trust Infrastructure

Atlas Trust Infrastructure is the public-facing trust model and documentation
surface for Atlas: a metadata-first trust control plane for authorized security
workflows, evidence retention, release trust, and business-flow proof.

Atlas originated inside Native Lab Toolkit, a local-first, shell-native
environment for authorized security assessment workflows. Native Lab Toolkit
keeps operator state, target records, shared intel, evidence, findings,
validation, reports, retention packets, and release trust artifacts in an
inspectable file-backed tree.

## Public Repository Purpose

This public repository explains Atlas' trust infrastructure model, safety
boundary, release evidence, business-flow evidence, and readiness language. The
private `atlas-lab-toolkit` repository remains the implementation home for
retained engineering context and operator runtime history.

`atlas` is the main operator control plane. It does not replace the domain
tools; it coordinates them:

- `atlas`: scope, operations, evidence, findings, validation, reports,
  retention, and release trust
- `wiremap`: reconnaissance, capture, and evidence interpretation
- `vector`: ranked action lanes, bounded validation, sessions, and outcomes
- `intelctl`: direct shared-intel inspection
- `labctl`: build, release, target, and administration workflows

## Start Here By Role

- New reader: [docs/ATLAS_ONE_PAGE.md](docs/ATLAS_ONE_PAGE.md)
- Security operator: [docs/OPERATOR_GUIDE.md](docs/OPERATOR_GUIDE.md)
- Business owner: [docs/atlas/BUSINESS_FLOW_EVIDENCE.md](docs/atlas/BUSINESS_FLOW_EVIDENCE.md)
- Release reviewer: [docs/RELEASE_TRUST.md](docs/RELEASE_TRUST.md)
- SLSA reviewer: [docs/atlas/SLSA_CLAIM.md](docs/atlas/SLSA_CLAIM.md)
- Contributor: [CONTRIBUTING.md](CONTRIBUTING.md)
- Security reporter: [SECURITY.md](SECURITY.md)

## Quick Start

Run from the repository root:

```bash
nix-shell
./bin/labctl status
./tools/atlas/bin/atlas doctor
./tools/atlas/bin/atlas v1 status --strict
./tools/atlas/bin/atlas production status --strict
```

Full local QA:

```bash
nix-shell --run './bin/dev-qa'
```

## Safety Boundary

Atlas is for authorized assessment orchestration only.

Do not use it for autonomous exploitation, persistence, destructive testing,
credential spraying, denial-of-service workflows, stealth/evasion behavior, or
out-of-scope target expansion. Target-touching workflows should preserve scope
checks, capability classification, operator intent, approval gates where
required, ledger events, and evidence handling.

## Current Maturity

Atlas can report `production-ready under the local Atlas contract` when all
retained release evidence verifies for the current retained release commit:

- v1 internal readiness is ready
- repository state is clean and synced
- release trust packet verification passes
- release artifact manifest verification passes
- production readiness contract exists
- signing/provenance verifies through a retained public key
- production dry-run evidence is retained

Atlas has a SLSA-verifiable release artifact candidate path for GitHub-built
artifacts: GitHub-hosted artifact attestation, official SLSA generic provenance,
retained Atlas SLSA metadata, and verifier commands. This is not external audit,
enterprise certification, SLSA certification, deployment
certification, immutable storage, or tamper-proof infrastructure.

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
| [docs/INDEX.md](docs/INDEX.md) | Documentation map for new reviewers. |
| [docs/ATLAS_ONE_PAGE.md](docs/ATLAS_ONE_PAGE.md) | One-page Atlas explanation. |
| [docs/OPERATOR_GUIDE.md](docs/OPERATOR_GUIDE.md) | End-to-end operator workflow. |
| [docs/demo/DEMO_OPERATION.md](docs/demo/DEMO_OPERATION.md) | Synthetic metadata-only demo operation. |
| [docs/COMMAND_REFERENCE.md](docs/COMMAND_REFERENCE.md) | Full command reference moved out of the README. |
| [docs/TRUST_LIFECYCLE.md](docs/TRUST_LIFECYCLE.md) | Scope-to-release trust chain explanation. |
| [docs/case-studies/CASE_STUDY_RELEASE_TRUST.md](docs/case-studies/CASE_STUDY_RELEASE_TRUST.md) | Public release-trust case study. |
| [docs/case-studies/CASE_STUDY_VENDOR_PAYMENT_CHANGE.md](docs/case-studies/CASE_STUDY_VENDOR_PAYMENT_CHANGE.md) | Public business-flow case study. |
| [docs/atlas/TRUST_INFRASTRUCTURE_DIRECTION.md](docs/atlas/TRUST_INFRASTRUCTURE_DIRECTION.md) | Atlas trust-infrastructure direction. |
| [docs/atlas/TRUST_OBJECT_MODEL.md](docs/atlas/TRUST_OBJECT_MODEL.md) | Actors, objects, packets, schemas, freshness, verification, and replay. |
| [docs/RELEASE_TRUST.md](docs/RELEASE_TRUST.md) | Release packets, verification, replay, signing, and provenance. |
| [docs/atlas/SLSA_PROVENANCE.md](docs/atlas/SLSA_PROVENANCE.md) | GitHub/Sigstore SLSA provenance workflow and verification contract. |
| [docs/atlas/SLSA_CLAIM.md](docs/atlas/SLSA_CLAIM.md) | Bounded SLSA-verifiable release artifact claim and evidence checklist. |
| [docs/atlas/RELEASE_ARTIFACT_MANIFEST.md](docs/atlas/RELEASE_ARTIFACT_MANIFEST.md) | Release artifact manifest contract and completeness checks. |
| [docs/WEB_ASSESSMENT.md](docs/WEB_ASSESSMENT.md) | `atlas web assess` flow and boundaries. |
| [docs/atlas/BUSINESS_FLOW_EVIDENCE.md](docs/atlas/BUSINESS_FLOW_EVIDENCE.md) | Optional metadata-only business-flow evidence model, retention links, packet path, assurance view, trust-chain view, verification, and non-blocking readiness integration. |
| [docs/atlas/V1_PILLAR_READINESS.md](docs/atlas/V1_PILLAR_READINESS.md) | v1 pillar readiness contract. |
| [docs/atlas/PRODUCTION_READINESS.md](docs/atlas/PRODUCTION_READINESS.md) | Local production readiness contract. |
| [docs/TRUST_MODEL.md](docs/TRUST_MODEL.md) | Trust model and verification pattern. |
| [docs/SECURITY_MODEL.md](docs/SECURITY_MODEL.md) | Safety model, tiers, and allowed boundaries. |
| [docs/RESPONSIBLE_USE.md](docs/RESPONSIBLE_USE.md) | Responsible-use policy. |
| [docs/KNOWN_LIMITATIONS.md](docs/KNOWN_LIMITATIONS.md) | Current limitations and language boundaries. |
| [docs/CI.md](docs/CI.md) | GitHub Actions and local QA parity. |
| [SECURITY.md](SECURITY.md) | Public vulnerability reporting and authorized-use boundary. |
| [CONTRIBUTING.md](CONTRIBUTING.md) | Contribution rules, QA expectations, and no-secrets policy. |

## Development

The development shell provides the expected local toolchain, including `bats`, `git`, `gpg`, `jq`, `rg`, `shellcheck`, and `shfmt`.

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
