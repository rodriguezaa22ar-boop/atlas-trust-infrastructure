# Milestone 70: Atlas Business Flow Evidence Spec

## Release Commit

`345de45d799e54600f712196578b9e698461415f` Add Atlas business flow evidence spec

## Purpose

Define Atlas Business Flow Evidence as an optional, metadata-only extension for
mapping business-critical workflows to Atlas evidence, findings, validation,
approvals, freshness, and retention packets without storing raw business data or
secrets.

## Added

- `docs/atlas/BUSINESS_FLOW_EVIDENCE.md`.
- `docs/schemas/business-flow-evidence.v1.md`.
- `docs/schemas/business-flow-packet.v1.md`.
- Schema index entries for planned Business Flow Evidence design contracts.
- Root README and docs index navigation for the new design.
- Root `AGENTS.md` invariant for referential, metadata-only business-flow
  evidence packets.
- Blueprint milestone entry for the spec-first Business Flow Evidence design.
- Test coverage that preserves the optional and metadata-only boundaries.

## Retained Evidence

- `docs/retention/releases/atlas-m70-business-flow-evidence.json`
- `docs/retention/releases/atlas-m70-business-flow-evidence.provenance.json`
- `docs/retention/production/PRODUCTION_DRY_RUN_2026-04-27_M70.md`
- Signed tag: `atlas-production-candidate-m70`

## Verified

- `git diff --check`
- `nix-shell --run 'bats --filter "README|business-flow evidence|schema docs" tests/atlas.bats'`: `3/3`
- `nix-shell --run './bin/dev-qa'`: `83/83`, lint ok, stress ok
- `./tools/atlas/bin/atlas release packet atlas-m70-business-flow-evidence --json --qa-status pass --qa-note "dev-qa passed before M70 business-flow evidence release packet"`
- `./tools/atlas/bin/atlas release verify docs/retention/releases/atlas-m70-business-flow-evidence.json --commit 345de45`: verified
- `git tag -v atlas-production-candidate-m70`: good signature

## Repo State

- Release commit: `345de45d799e54600f712196578b9e698461415f`.
- Release packet retained.
- Release provenance packet retained.
- Production dry-run note retained.
- Business Flow Evidence remains planned and optional; no runtime `atlas flow`
  commands are implemented in this milestone.
- Operation-scoped readiness for active operations may still report operation
  findings; this milestone is repository release evidence, not an operation
  closeout.
- Production readiness remains a local contract, not an external audit or
  deployment certification.
