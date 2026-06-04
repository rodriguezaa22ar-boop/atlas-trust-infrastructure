# Milestone 174: Adapter Registry Draft

## Reviewed Commit

`07bb4aea8d929b991d38fa07f85793dac31f144e` M173 capability manifest safety
regression

## Purpose

Create the first machine-readable adapter registry draft for Atlas so external
systems can be represented before any live adapter execution exists.

M174 is the value step after the M173 capability manifest safety hardening
step.

## Added

- Expanded `adapters/registry.yaml` into the M174 adapter registry draft with
  `schema_version: atlas.adapter_registry.v1`, `default_mode: deny`, draft
  status, `live_integrations_enabled: false`, and `metadata_only: true`.
- Added draft adapter entries for generic external events, GitHub Actions
  metadata, GitHub release verification metadata, scanner finding metadata,
  ticket issue metadata, ticket transition proposals, AI-agent action metadata,
  cloud change proposals, and business workflow event metadata.
- Updated `bin/dev-adapters` so the validation gate checks the M174 registry
  shape, known capabilities, metadata-only posture, no live integrations, no
  active mutation, proposal approval posture, and safe evidence outputs.
- Added `docs/governance/ADAPTER_REGISTRY_M174.md`.
- Updated the stable adapter registry doc to point to the M174 draft.
- Added focused Bats coverage for the M174 adapter registry draft and bounded
  adapter language.
- Updated the docs index and milestone index.

## Validation

- `git diff --check`: pass.
- Focused M174 adapter registry Bats: pass.
- `./bin/dev-adapters`: pass.
- `./bin/dev-governance`: pass.
- `./bin/export-public-trust --check`: pass.
- `nix-shell --run './bin/dev-qa'`: pass.

## Boundaries

- Docs/tests/schema/tooling only.
- No Atlas runtime adapter execution added.
- No live integration added.
- No GitHub API calls added.
- No webhook server added.
- No network collector added.
- No credential handling added.
- No policy engine added.
- No approval engine added.
- No database/server/web UI added.
- No receipt semantics changed.
- No runtime mutation added.
- Existing external systems remain the source of their own operational truth.
- Known limitations preserved.
- Tag target: `atlas-retention-m174`.
