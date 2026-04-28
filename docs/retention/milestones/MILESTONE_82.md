# Milestone 82: Atlas Business Flow Approval Links

## Release Commit

`bd0711f175135d67d922760d6245d5794db4213b` Add Atlas business flow approval links

## Purpose

Extend optional Business Flow Evidence from evidence, finding, and validation
context into operation approval context without embedding approval reasons,
reviewer rationale, operator notes, command output, or raw evidence.

## Added

- `atlas flow link-approval <flow> <capability>`.
- `atlas.flow_approval_link.v1` records under
  `sessions/<operation>/flow_approvals.ndjson`.
- Flow approval links to the latest approved operation capability for the active
  target.
- Business-flow Markdown and JSON packets now include approval references, link
  counts, and approval freshness metadata.
- Business-flow Markdown and JSON verification now checks linked approvals,
  current approval records, packet references, and stale state.
- Updated schema, command, readiness, trust-object, roadmap, blueprint, and
  operator docs.
- Tests covering missing approvals, metadata-only link records, packet inclusion,
  JSON packet inclusion, read-only verification, and stale approval-link
  detection.

## Retained Evidence

- `docs/retention/releases/atlas-m82-business-flow-approval-links.json`
- `docs/retention/releases/atlas-m82-business-flow-approval-links.provenance.json`
- `docs/retention/production/PRODUCTION_DRY_RUN_2026-04-27_M82.md`
- Signed tag: `atlas-production-candidate-m82`

## Verified

- `bash -n tools/atlas/lib/flows.sh tools/atlas/bin/atlas tools/atlas/lib/v1.sh tools/atlas/lib/production.sh`
- `git diff --check`
- `nix-shell --run 'bats tests/atlas.bats --filter "business-flow evidence design|atlas flow link|atlas flow packet|atlas flow verify|atlas help|atlas v1 status|business-flow evidence readiness|atlas production status"'`: `12/12`
- `nix-shell --run './bin/dev-lint'`: lint ok
- `nix-shell --run './bin/dev-qa'`: `94/94`, lint ok, stress ok
- `./tools/atlas/bin/atlas release packet atlas-m82-business-flow-approval-links --json --qa-status pass --qa-command "nix-shell --run './bin/dev-qa'" --qa-note "dev-qa passed with 94/94 tests, lint ok, and stress ok before M82 business-flow approval link release packet"`
- `./tools/atlas/bin/atlas release verify atlas-m82-business-flow-approval-links --commit bd0711f`: verified
- `./tools/atlas/bin/atlas release replay atlas-m82-business-flow-approval-links --skip-qa`: verified
- `git tag -v atlas-production-candidate-m82`: good signature

## Repo State

- Release commit: `bd0711f175135d67d922760d6245d5794db4213b`.
- Release packet retained.
- Release provenance packet retained.
- Production dry-run note retained.
- Business Flow Evidence approval links are implemented and verified.
- Business Flow Evidence remains optional and non-blocking.
- Retention links, flow trust-chain integration, schema-generated validation,
  and required-pillar promotion remain planned later steps.
