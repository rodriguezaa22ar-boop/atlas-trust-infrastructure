# Milestone 76: Atlas Business Flow Packets

## Release Commit

`0ab2e1addedb3f0aec3565f90a49f85f12d061dd` Add Atlas business flow packets

## Purpose

Promote Business Flow Evidence from records and evidence links to retained,
operation-scoped metadata-only packets.

## Added

- `atlas flow packet <flow> [packet-name]`.
- Operation-scoped flow packet directory:
  `sessions/<operation>/flow_packets/`.
- Metadata-only Markdown packet with flow identity, operation and target
  metadata, systems, data classes, control objectives, evidence IDs, retained
  evidence paths, SHA-256 hashes, classification, redaction state, freshness
  metadata, and known limitations.
- Required active-operation and existing flow evidence-link checks before packet
  generation.
- Packet forbidden-content scan before successful completion.
- `flow.packet.generated` ledger event.
- Tests proving packet generation, missing active operation failure, missing
  flow-link failure, metadata-only output, no raw evidence-body embedding, and
  retained ledger event.
- Documentation updates across the README, command reference, Business Flow
  Evidence spec, packet schema, packet parity matrix, trust object model,
  trust infrastructure direction, roadmap, and blueprint.

## Retained Evidence

- `docs/retention/releases/atlas-m76-business-flow-packets.json`
- `docs/retention/releases/atlas-m76-business-flow-packets.provenance.json`
- `docs/retention/production/PRODUCTION_DRY_RUN_2026-04-27_M76.md`
- Signed tag: `atlas-production-candidate-m76`

## Verified

- `bash -n tools/atlas/bin/atlas`
- `bash -n tools/atlas/lib/flows.sh`
- `git diff --check`
- `nix-shell --run 'bats --filter "business-flow evidence|atlas flow|atlas help" tests/atlas.bats'`: `5/5`
- `nix-shell --run 'bats --filter "root README|business-flow evidence|atlas flow|packet format parity|schema docs|atlas trust" tests/atlas.bats'`: `10/10`
- `nix-shell --run './bin/dev-qa'`: `89/89`, lint ok, stress ok
- `./tools/atlas/bin/atlas release packet atlas-m76-business-flow-packets --json --qa-status pass --qa-command "nix-shell --run './bin/dev-qa'" --qa-note "dev-qa passed with 89/89 tests, lint ok, and stress ok before M76 business-flow packet release packet"`
- `./tools/atlas/bin/atlas release verify docs/retention/releases/atlas-m76-business-flow-packets.json --commit 0ab2e1a`: verified
- `./tools/atlas/bin/atlas release replay docs/retention/releases/atlas-m76-business-flow-packets.json`: QA ok, v1 status ok, release verify ok
- `git tag -v atlas-production-candidate-m76`: good signature

## Repo State

- Release commit: `0ab2e1addedb3f0aec3565f90a49f85f12d061dd`.
- Release packet retained.
- Release provenance packet retained.
- Production dry-run note retained.
- Business Flow Evidence packet generation is implemented and covered by tests.
- `atlas flow verify`, Business Flow Evidence JSON parity, finding and
  validation links, retention references, and optional readiness integration
  remain planned later steps.
