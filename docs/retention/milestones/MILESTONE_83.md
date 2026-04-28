# Milestone 83: Atlas Business Flow Trust-Chain Visibility

## Release Commit

`4e25cb2b28f8aa704a4a946366776f0208eca6cf` Add Atlas business flow trust-chain visibility

## Purpose

Make optional Business Flow Evidence visible in the operation trust-chain view
without making it required, mutating state, or embedding raw evidence, approval
reasons, operator notes, or sensitive business data.

## Added

- `atlas op trust-chain` now prints a Business Flow Evidence section.
- `atlas op trust-chain --json` now emits a `business_flow_evidence` object.
- Operation trust-chain output includes counts for:
  - operation flow links
  - evidence links
  - finding links
  - validation links
  - approval links
  - Markdown flow packets
  - JSON flow packets
- `atlas.operation_trust_chain.v1` documents the optional
  `business_flow_evidence` object.
- Trust lifecycle, Business Flow Evidence, readiness, roadmap, blueprint, and
  trust-object docs now reflect operation trust-chain visibility.
- Tests prove trust-chain flow visibility is read-only and metadata-only.

## Retained Evidence

- `docs/retention/releases/atlas-m83-business-flow-trust-chain.json`
- `docs/retention/releases/atlas-m83-business-flow-trust-chain.provenance.json`
- `docs/retention/production/PRODUCTION_DRY_RUN_2026-04-27_M83.md`
- Signed tag: `atlas-production-candidate-m83`

## Verified

- `bash -n tools/atlas/lib/trust.sh tools/atlas/bin/atlas`
- `git diff --check`
- `nix-shell --run 'bats tests/atlas.bats --filter "op trust-chain surfaces business-flow|schema docs pin|atlas trust lifecycle|operation archive"'`: `4/4`
- `nix-shell --run './bin/dev-lint'`: lint ok
- `nix-shell --run './bin/dev-qa'`: `95/95`, lint ok, stress ok
- `./tools/atlas/bin/atlas release packet atlas-m83-business-flow-trust-chain --json --qa-status pass --qa-command "nix-shell --run './bin/dev-qa'" --qa-note "dev-qa passed with 95/95 tests, lint ok, and stress ok before M83 business-flow trust-chain visibility release packet"`
- `./tools/atlas/bin/atlas release verify atlas-m83-business-flow-trust-chain --commit 4e25cb2`: verified
- `./tools/atlas/bin/atlas release replay atlas-m83-business-flow-trust-chain --skip-qa`: verified
- `git tag -v atlas-production-candidate-m83`: good signature

## Repo State

- Release commit: `4e25cb2b28f8aa704a4a946366776f0208eca6cf`.
- Release packet retained.
- Release provenance packet retained.
- Production dry-run note retained.
- Business Flow Evidence operation trust-chain visibility is implemented and
  verified.
- Business Flow Evidence remains optional and non-blocking.
- Retention links, a flow-specific trust-chain command, schema-generated
  validation, and required-pillar promotion remain planned later steps.
