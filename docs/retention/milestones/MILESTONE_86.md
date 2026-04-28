# Milestone 86: Atlas Archive Packet JSON Parity

## Release Commit

`7ff15baad57543e1d0107a1071409e0e168e5637` Add Atlas archive packet JSON parity

## Purpose

Give operation archive packets a machine-readable contract while preserving the
existing Markdown packet and read-only archive verification workflow.

## Added

- `atlas op archive-packet --json [name] [packet-name]`.
- JSON archive packet schema `atlas.archive_packet.v1`.
- JSON packet fields for:
  - operation identity
  - metadata-only and raw-artifact guardrails
  - archive status
  - readiness freshness
  - closeout, accepted-risk review packet, and audit packet verification state
  - retained artifact paths and SHA-256 anchors
  - operation ledger event count and SHA-256 anchor
  - known limitations
- `atlas op archive-verify` now accepts Markdown or JSON archive packets.
- JSON archive verification checks:
  - schema version
  - operation id
  - metadata-only flags
  - forbidden raw-content markers
  - retained file hashes
  - operation ledger anchor
- Packet format parity docs now mark archive packets implemented and leave audit
  packet JSON parity as the next packet gap.
- Schema docs, command references, operator walkthroughs, roadmap, blueprint,
  trust lifecycle, and Atlas README now reflect archive JSON parity.

## Retained Evidence

- `docs/retention/releases/atlas-m86-archive-packet-json-parity.json`
- `docs/retention/releases/atlas-m86-archive-packet-json-parity.provenance.json`
- `docs/retention/production/PRODUCTION_DRY_RUN_2026-04-27_M86.md`
- Signed tag: `atlas-production-candidate-m86`

## Verified

- `bash -n tools/atlas/lib/archive.sh tools/atlas/bin/atlas`
- `git diff --check`
- `nix-shell --run 'bats tests/atlas.bats -f "atlas operation archive summarizes final verification state"'`: `1/1`
- `nix-shell --run 'bats tests/atlas.bats -f "packet format parity matrix records implemented JSON and packet gaps"'`: `1/1`
- `nix-shell --run 'bats tests/atlas.bats -f "schema docs pin implemented Atlas JSON contracts"'`: `1/1`
- `nix-shell --run 'bats tests/atlas.bats -f "atlas help groups target-first workflow and story commands"'`: `1/1`
- `nix-shell --run './bin/dev-lint'`: lint ok
- `nix-shell --run './bin/dev-qa'`: `97/97`, lint ok, stress ok
- `./tools/atlas/bin/atlas v1 status --strict`: ready
- `./tools/atlas/bin/atlas release packet atlas-m86-archive-packet-json-parity --json --qa-status pass --qa-command "nix-shell --run './bin/dev-qa'" --qa-note "dev-qa passed with 97/97 tests, lint ok, and stress ok before M86 archive packet JSON parity release packet"`
- `./tools/atlas/bin/atlas release verify docs/retention/releases/atlas-m86-archive-packet-json-parity.json --commit 7ff15baad57543e1d0107a1071409e0e168e5637`: verified
- `./tools/atlas/bin/atlas release replay docs/retention/releases/atlas-m86-archive-packet-json-parity.json --skip-qa`: verified
- `git tag -v atlas-production-candidate-m86`: good signature

## Repo State

- Release commit: `7ff15baad57543e1d0107a1071409e0e168e5637`.
- Release packet retained.
- Release provenance packet retained.
- Production dry-run note retained.
- Archive packet JSON parity is implemented and verified.
- Audit packet JSON parity remains the next packet-format gap.
- No production-ready claim is made.
