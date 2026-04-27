# Milestone 74: Atlas Trust Object Model

## Release Commit

`139797a049e5fea6d37f475b5fa4381465913591` Add Atlas trust object model

## Purpose

Convert the revised trust infrastructure blueprint into a concrete Atlas trust
object model for actors, objects, packets, schemas, freshness, verification,
replay, retention, and readiness language.

## Added

- `docs/atlas/TRUST_OBJECT_MODEL.md`.
- Trust actor model for operator, business owner, reviewer, auditor, system
  owner, and release owner.
- Trust object model for targets, operations, business flows, scope snapshots,
  ledger events, evidence records, findings, accepted risks, validation,
  approvals, reports, packets, schema contracts, and milestone notes.
- Packet class definitions for handoff, closeout, audit, archive, release,
  provenance, production dry-run, advisor, and future business-flow packets.
- Schema contract expectations for required fields, allowed values, forbidden
  content, verification rules, replay expectations, limitations, and non-goals.
- Freshness states: `missing`, `current`, `stale`, and `blocked`.
- Verification and replay model that records the current truth: `atlas release
  verify` exists, operation trust-chain replay happens during release
  verification, and a future `atlas release replay` command is not claimed until
  implemented.
- Direction doc, roadmap, README, docs index, schema index, and blueprint links
  to the trust object model.
- Bats coverage for the trust object model and no-overclaim replay wording.

## Retained Evidence

- `docs/retention/releases/atlas-m74-trust-object-model.json`
- `docs/retention/releases/atlas-m74-trust-object-model.provenance.json`
- `docs/retention/production/PRODUCTION_DRY_RUN_2026-04-27_M74.md`
- Signed tag: `atlas-production-candidate-m74`

## Verified

- `git diff --check`
- `nix-shell --run 'bats --filter "trust object model|trust infrastructure|root README|schema docs" tests/atlas.bats'`: `4/4`
- `nix-shell --run './bin/dev-qa'`: `87/87`, lint ok, stress ok
- `./tools/atlas/bin/atlas release packet atlas-m74-trust-object-model --json --qa-status pass --qa-command "nix-shell --run './bin/dev-qa'" --qa-note "dev-qa passed before M74 trust object model release packet"`
- `./tools/atlas/bin/atlas release verify docs/retention/releases/atlas-m74-trust-object-model.json --commit 139797a`: verified
- `git tag -v atlas-production-candidate-m74`: good signature

## Repo State

- Release commit: `139797a049e5fea6d37f475b5fa4381465913591`.
- Release packet retained.
- Release provenance packet retained.
- Production dry-run note retained.
- The revised blueprint text is represented as repo-native Markdown contracts,
  not as a retained binary PDF.
- `atlas release replay` remains a future command; the current implemented
  surface is `atlas release verify` plus the retained clean-checkout replay
  runbook.
- Business Flow Evidence remains optional.
- `atlas flow packet`, `atlas flow verify`, and optional readiness integration
  remain the next planned Business Flow Evidence steps.
