# Native Lab Toolkit

Native Lab Toolkit is a local-first, shell-native toolkit for authorized
security assessment workflows. It keeps operator state, target records, shared
intel, evidence, findings, validation, reports, retention packets, and release
trust artifacts in an inspectable file-backed tree.

Atlas is evolving into metadata-first trust infrastructure: a control plane for
security-operation proof, business-flow evidence, release trust, auditability,
retention, verification, and later business/process assurance.

`atlas` is the main operator control plane. It does not replace the domain
tools; it coordinates them:

- `atlas`: scope, operations, evidence, findings, validation, reports,
  retention, and release trust
- `wiremap`: reconnaissance, capture, and evidence interpretation
- `vector`: ranked action lanes, bounded validation, sessions, and outcomes
- `intelctl`: direct shared-intel inspection
- `labctl`: build, release, target, and administration workflows

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

Atlas can report `production-ready` under its local production contract when
all retained release evidence verifies for the current retained release commit:

- v1 internal readiness is ready
- repository state is clean and synced
- release trust packet verification passes
- release artifact manifest verification passes
- production readiness contract exists
- signing/provenance verifies through a retained public key
- production dry-run evidence is retained

Release artifacts can be built through the SLSA provenance workflow, but Atlas
does not claim external audit, enterprise certification, SLSA certification,
deployment certification, immutable storage, or tamper-proof infrastructure. It
means the local Atlas gates pass against retained evidence.

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
| [docs/COMMAND_REFERENCE.md](docs/COMMAND_REFERENCE.md) | Full command reference moved out of the README. |
| [docs/TRUST_LIFECYCLE.md](docs/TRUST_LIFECYCLE.md) | Scope-to-release trust chain explanation. |
| [docs/atlas/TRUST_INFRASTRUCTURE_DIRECTION.md](docs/atlas/TRUST_INFRASTRUCTURE_DIRECTION.md) | Atlas trust-infrastructure direction. |
| [docs/atlas/TRUST_OBJECT_MODEL.md](docs/atlas/TRUST_OBJECT_MODEL.md) | Actors, objects, packets, schemas, freshness, verification, and replay. |
| [docs/RELEASE_TRUST.md](docs/RELEASE_TRUST.md) | Release packets, verification, replay, signing, and provenance. |
| [docs/atlas/SLSA_PROVENANCE.md](docs/atlas/SLSA_PROVENANCE.md) | GitHub/Sigstore SLSA provenance workflow and verification contract. |
| [docs/atlas/SLSA_CLAIM.md](docs/atlas/SLSA_CLAIM.md) | Bounded SLSA-verifiable release artifact claim and evidence checklist. |
| [docs/atlas/RELEASE_ARTIFACT_MANIFEST.md](docs/atlas/RELEASE_ARTIFACT_MANIFEST.md) | Release artifact manifest contract and completeness checks. |
| [docs/WEB_ASSESSMENT.md](docs/WEB_ASSESSMENT.md) | `atlas web assess` flow and boundaries. |
| [docs/atlas/BUSINESS_FLOW_EVIDENCE.md](docs/atlas/BUSINESS_FLOW_EVIDENCE.md) | Optional metadata-only business-flow evidence model, retention links, packet path, assurance view, trust-chain view, verification, and non-blocking readiness integration. |
| [docs/ATLAS_BLUEPRINT.md](docs/ATLAS_BLUEPRINT.md) | Product architecture and milestone history. |
| [docs/atlas/V1_PILLAR_READINESS.md](docs/atlas/V1_PILLAR_READINESS.md) | v1 pillar readiness contract. |
| [docs/atlas/PRODUCTION_READINESS.md](docs/atlas/PRODUCTION_READINESS.md) | Local production readiness contract. |
| [docs/TRUST_MODEL.md](docs/TRUST_MODEL.md) | Trust model and verification pattern. |
| [docs/SECURITY_MODEL.md](docs/SECURITY_MODEL.md) | Safety model, tiers, and allowed boundaries. |
| [docs/RESPONSIBLE_USE.md](docs/RESPONSIBLE_USE.md) | Responsible-use policy. |
| [docs/KNOWN_LIMITATIONS.md](docs/KNOWN_LIMITATIONS.md) | Current limitations and language boundaries. |
| [docs/CI.md](docs/CI.md) | GitHub Actions and local QA parity. |
| [SECURITY.md](SECURITY.md) | Public vulnerability reporting and authorized-use boundary. |
| [CONTRIBUTING.md](CONTRIBUTING.md) | Contribution rules, QA expectations, and no-secrets policy. |

## Repository Layout

- `bin/`: top-level entrypoints and development helpers
- `lib/`: shared shell helpers
- `tools/`: native tool modules
- `targets/`: target records
- `sessions/`: per-session workspaces
- `reports/`: generated operation reports
- `state/`: shared state, run history, and cross-tool intel
- `docs/`: architecture, operator, trust, release, and retention docs

## Development

The development shell provides the expected local toolchain, including
`bats`, `git`, `gpg`, `jq`, `rg`, `shellcheck`, and `shfmt`.

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
