# Milestone 85: Atlas Flow Trust-Chain Status

## Release Commit

`ca2975039ae617704fa7e4ec3f6da255d9504241` Add Atlas flow trust-chain status

## Purpose

Make a single optional Business Flow Evidence record independently inspectable
without making business flows required, mutating operation state, or embedding
raw evidence, retained artifact bodies, approval reasons, operator notes, or
sensitive business data.

## Added

- `atlas flow trust-chain <flow> [packet-name]`.
- `atlas flow trust-chain --json <flow> [packet-name]`.
- JSON schema contract `atlas.business_flow_trust_chain.v1`.
- Single-flow trust-chain status values:
  - `not-recorded`
  - `linked`
  - `current`
  - `attention-required`
- Flow trust-chain output includes:
  - operation, evidence, finding, validation, approval, and retention link counts
  - Markdown and JSON packet presence
  - selected packet verification status
  - verifier checks when a JSON packet exists
  - next operator step
- Readiness, production status, command reference, Business Flow Evidence docs,
  schema index, packet parity docs, roadmap, blueprint, and trust-object docs
  now reflect the flow trust-chain command.
- Tests prove the command is read-only, reports linked/current/stale states, and
  surfaces JSON verifier checks without writing ledger events.

## Retained Evidence

- `docs/retention/releases/atlas-m85-flow-trust-chain-status.json`
- `docs/retention/releases/atlas-m85-flow-trust-chain-status.provenance.json`
- `docs/retention/production/PRODUCTION_DRY_RUN_2026-04-27_M85.md`
- Signed tag: `atlas-production-candidate-m85`

## Verified

- `bash -n tools/atlas/lib/flows.sh tools/atlas/lib/v1.sh tools/atlas/lib/production.sh tools/atlas/bin/atlas`
- `git diff --check`
- `nix-shell --run 'bats tests/atlas.bats --filter "business-flow evidence design|atlas flow link|atlas flow packet|atlas flow verify|atlas op trust-chain surfaces business-flow|atlas flow trust-chain|atlas help|atlas v1 status|business-flow evidence readiness|atlas production status|schema docs pin|packet format parity"'`: `17/17`
- `nix-shell --run './bin/dev-lint'`: lint ok
- `nix-shell --run './bin/dev-qa'`: `97/97`, lint ok, stress ok
- `./tools/atlas/bin/atlas release packet atlas-m85-flow-trust-chain-status --json --qa-status pass --qa-command "nix-shell --run './bin/dev-qa'" --qa-note "dev-qa passed with 97/97 tests, lint ok, and stress ok before M85 flow trust-chain status release packet"`
- `./tools/atlas/bin/atlas release verify atlas-m85-flow-trust-chain-status --commit ca29750`: verified
- `./tools/atlas/bin/atlas release replay atlas-m85-flow-trust-chain-status --skip-qa`: verified
- `git tag -v atlas-production-candidate-m85`: good signature

## Repo State

- Release commit: `ca2975039ae617704fa7e4ec3f6da255d9504241`.
- Release packet retained.
- Release provenance packet retained.
- Production dry-run note retained.
- Business Flow Evidence flow trust-chain status is implemented and verified.
- Business Flow Evidence remains optional and non-blocking.
- Schema-generated validation and required-pillar promotion remain planned later
  steps.
