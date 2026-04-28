# Milestone 81: Atlas Business Flow Finding And Validation Links

## Release Commit

`14c511b8d4ccb25a764019be3086b01ff2683059` Add Atlas business flow finding validation links

## Purpose

Extend optional Business Flow Evidence beyond evidence references by linking
flows to existing Atlas findings and validation plans without embedding raw
finding bodies, validation reasons, plan contents, session contents, or raw
evidence.

## Added

- `atlas flow link-finding <flow> <finding-id>`.
- `atlas flow link-validation <flow> <validation-id>`.
- `atlas.flow_finding_link.v1` records under
  `sessions/<operation>/flow_findings.ndjson`.
- `atlas.flow_validation_link.v1` records under
  `sessions/<operation>/flow_validation.ndjson`.
- Business-flow Markdown and JSON packets now include finding and validation
  references, link counts, and freshness metadata.
- Business-flow Markdown and JSON verification now checks linked findings,
  linked validation plans, current metadata, packet references, and stale
  state.
- Updated schema, command, readiness, trust-object, roadmap, blueprint, and
  operator docs.
- Tests covering missing finding/validation IDs, metadata-only link records,
  packet inclusion, JSON packet inclusion, read-only verification, and stale
  validation metadata detection.

## Retained Evidence

- `docs/retention/releases/atlas-m81-business-flow-context-links.json`
- `docs/retention/releases/atlas-m81-business-flow-context-links.provenance.json`
- `docs/retention/production/PRODUCTION_DRY_RUN_2026-04-27_M81.md`
- Signed tag: `atlas-production-candidate-m81`

## Verified

- `bash -n tools/atlas/lib/flows.sh tools/atlas/bin/atlas`
- `bash -n tools/atlas/lib/flows.sh tools/atlas/bin/atlas tools/atlas/lib/v1.sh tools/atlas/lib/production.sh`
- `git diff --check`
- `nix-shell --run 'bats tests/atlas.bats --filter "atlas flow link|atlas flow packet|atlas flow verify|atlas help"'`: `6/6`
- `nix-shell --run 'bats tests/atlas.bats --filter "business-flow evidence design|schema docs pin|atlas flow link|atlas flow packet|atlas flow verify|atlas help|atlas v1 status|business-flow evidence readiness|atlas production status"'`: `12/12`
- `nix-shell --run './bin/dev-lint'`: lint ok
- `nix-shell --run './bin/dev-qa'`: `93/93`, lint ok, stress ok
- `./tools/atlas/bin/atlas release packet atlas-m81-business-flow-context-links --json --qa-status pass --qa-command "nix-shell --run './bin/dev-qa'" --qa-note "dev-qa passed with 93/93 tests, lint ok, and stress ok before M81 business-flow finding and validation link release packet"`
- `./tools/atlas/bin/atlas release verify atlas-m81-business-flow-context-links --commit 14c511b`: verified
- `./tools/atlas/bin/atlas release replay atlas-m81-business-flow-context-links --skip-qa`: verified
- `git tag -v atlas-production-candidate-m81`: good signature

## Repo State

- Release commit: `14c511b8d4ccb25a764019be3086b01ff2683059`.
- Release packet retained.
- Release provenance packet retained.
- Production dry-run note retained.
- Business Flow Evidence finding and validation links are implemented and
  verified.
- Business Flow Evidence remains optional and non-blocking.
- Approval links, retention links, flow trust-chain integration,
  schema-generated validation, and required-pillar promotion remain planned
  later steps.
