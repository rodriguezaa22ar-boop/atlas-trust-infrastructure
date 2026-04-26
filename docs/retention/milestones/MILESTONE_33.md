# Milestone 33: Atlas Release Trust Packets

## Commit

`93ca144 Add Atlas release trust packets`

## Purpose

Make Atlas release readiness exportable as a metadata-only trust packet.

## Added

- `atlas release packet [packet-name]`
- Release trust packet writer under `docs/retention/releases/`
- Commit, branch, tag, cleanliness, and upstream sync metadata
- Embedded v1 readiness JSON
- QA status, command, and note fields
- Retained milestone note references
- Known limitations from the v1 pillar contract
- Metadata-only guardrail excluding raw runtime artifacts, target secrets,
  session contents, packet captures, and evidence bodies

## Verified

- `atlas release packet` writes a metadata-only packet
- `atlas v1 status --strict` remains ready
- `nix-shell --run './bin/dev-qa'`
- `tests/atlas.bats`: 63/63
- lint ok
- stress ok

## Repo State

- implementation committed
- current release packet command is documented in the root README and Atlas README
- blueprint records Milestone 33

## Follow-On Verification

Milestone 34 hardens this packet into a release gate by making packet
generation fail closed for dirty, unsynced, or not-ready repository states and
adding `atlas release verify`.
