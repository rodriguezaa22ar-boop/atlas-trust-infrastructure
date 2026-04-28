# Milestone 84: Atlas Business Flow Retention Links

## Release Commit

`ce779d2ef5d689d2b09bd7f53d7256cafc57ccd2` Add Atlas business flow retention links

## Purpose

Let optional Business Flow Evidence point to retained reports, handoff packets,
closeout manifests, audit packets, archive packets, release packets, and
accepted-risk review packets without embedding retained artifact contents.

## Added

- `atlas flow link-retention <flow> <kind> <path>`.
- Operation-scoped `atlas.flow_retention_link.v1` records under
  `sessions/<operation>/flow_retention.ndjson`.
- Metadata-only retention link fields:
  - retention kind
  - retained artifact path
  - retained artifact basename
  - retained artifact SHA-256
  - link timestamp
  - metadata-only boundary note
- Markdown and JSON Business Flow Evidence packets now include retention
  references and retention freshness counts.
- Markdown and JSON `atlas flow verify` now check retention link counts,
  packet references, retained artifact existence, and retained artifact hashes.
- Operation trust-chain text and JSON now report Business Flow Evidence
  retention-link counts.
- Business Flow Evidence schemas, command references, readiness docs, roadmap,
  blueprint, and trust-object docs now reflect retention links.
- Tests prove retention links are metadata-only, reject missing/invalid inputs,
  verify current packets, detect stale links, and block on retained-artifact
  hash drift.

## Retained Evidence

- `docs/retention/releases/atlas-m84-business-flow-retention-links.json`
- `docs/retention/releases/atlas-m84-business-flow-retention-links.provenance.json`
- `docs/retention/production/PRODUCTION_DRY_RUN_2026-04-27_M84.md`
- Signed tag: `atlas-production-candidate-m84`

## Verified

- `bash -n tools/atlas/lib/flows.sh tools/atlas/lib/trust.sh tools/atlas/lib/v1.sh tools/atlas/lib/production.sh tools/atlas/bin/atlas`
- `git diff --check`
- `nix-shell --run 'bats tests/atlas.bats --filter "business-flow evidence design|atlas flow link|atlas flow packet|atlas flow verify|atlas op trust-chain surfaces business-flow|atlas help|atlas v1 status|business-flow evidence readiness|atlas production status|schema docs pin"'`: `15/15`
- `nix-shell --run './bin/dev-lint'`: lint ok
- `nix-shell --run './bin/dev-qa'`: `96/96`, lint ok, stress ok
- `./tools/atlas/bin/atlas release packet atlas-m84-business-flow-retention-links --json --qa-status pass --qa-command "nix-shell --run './bin/dev-qa'" --qa-note "dev-qa passed with 96/96 tests, lint ok, and stress ok before M84 business-flow retention link release packet"`
- `./tools/atlas/bin/atlas release verify atlas-m84-business-flow-retention-links --commit ce779d2`: verified
- `./tools/atlas/bin/atlas release replay atlas-m84-business-flow-retention-links --skip-qa`: verified
- `git tag -v atlas-production-candidate-m84`: good signature

## Repo State

- Release commit: `ce779d2ef5d689d2b09bd7f53d7256cafc57ccd2`.
- Release packet retained.
- Release provenance packet retained.
- Production dry-run note retained.
- Business Flow Evidence retention links are implemented and verified.
- Business Flow Evidence remains optional and non-blocking.
- A flow-specific trust-chain command, schema-generated validation, and
  required-pillar promotion remain planned later steps.
