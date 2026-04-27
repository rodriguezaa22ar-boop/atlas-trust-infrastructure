# Milestone 71: Atlas Business Flow Records

## Release Commit

`038c8df117729e8266fd41135159773289ce548d` Add Atlas business flow records

## Purpose

Add the first runtime slice for Atlas Business Flow Evidence: optional,
metadata-only global flow records that describe business-critical workflows
without storing sensitive business content.

## Added

- `tools/atlas/lib/flows.sh`.
- `atlas flow add <flow-name>`.
- `atlas flow list`.
- `atlas flow show <flow>`.
- File-backed records under `state/atlas/flows/<flow-slug>.env`.
- `atlas.business_flow.v1` env-record fields for flow identity, owner,
  criticality, environment, scope status, data class labels, system aliases, and
  control objective labels.
- Basic forbidden-marker rejection for obvious secret-bearing values.
- Help, command reference, Atlas README, Business Flow Evidence docs, and
  blueprint updates.
- Tests for add/list/show, metadata-only record shape, and forbidden-marker
  rejection.

## Retained Evidence

- `docs/retention/releases/atlas-m71-business-flow-records.json`
- `docs/retention/releases/atlas-m71-business-flow-records.provenance.json`
- `docs/retention/production/PRODUCTION_DRY_RUN_2026-04-27_M71.md`
- Signed tag: `atlas-production-candidate-m71`

## Verified

- `bash -n tools/atlas/bin/atlas tools/atlas/lib/flows.sh`
- `git diff --check`
- `nix-shell --run './bin/dev-lint'`: lint ok
- `nix-shell --run 'bats --filter "business-flow evidence|atlas flow|atlas help groups|root README" tests/atlas.bats'`: `4/4`
- `nix-shell --run './bin/dev-qa'`: `84/84`, lint ok, stress ok
- `./tools/atlas/bin/atlas release packet atlas-m71-business-flow-records --json --qa-status pass --qa-note "dev-qa passed before M71 business-flow records release packet"`
- `./tools/atlas/bin/atlas release verify docs/retention/releases/atlas-m71-business-flow-records.json --commit 038c8df`: verified
- `git tag -v atlas-production-candidate-m71`: good signature

## Real-Business Smoke Test

Metadata-only flow records were created locally for:

- Ascend and Defend Academy service delivery.
- Execution OS SaaS subscription.

The smoke test used only labels, system aliases, data class labels, and control
objective labels. No secrets, customer records, payment data, request/response
bodies, tokens, or raw evidence were stored.

## Repo State

- Release commit: `038c8df117729e8266fd41135159773289ce548d`.
- Release packet retained.
- Release provenance packet retained.
- Production dry-run note retained.
- Business Flow Evidence remains optional.
- `atlas flow link-evidence`, `atlas flow packet`, `atlas flow verify`, and
  readiness integration remain planned.
- Production readiness remains a local contract, not an external audit or
  deployment certification.
