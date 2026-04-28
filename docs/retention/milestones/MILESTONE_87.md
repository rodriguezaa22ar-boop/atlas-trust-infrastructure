# Milestone 87: Atlas Audit Packet JSON Parity

## Release Commit

`c7dffbb1d9cf3dad429835a3dc03b8f1e312e466` Add Atlas audit packet JSON parity

## Purpose

Give operation audit packets a machine-readable contract while preserving the
existing Markdown audit packet and read-only audit verification workflow.

## Added

- `atlas op audit-packet --json [name] [packet-name]`.
- JSON audit packet schema `atlas.audit_packet.v1`.
- JSON packet fields for:
  - operation identity
  - metadata-only and raw-artifact guardrails
  - operation ledger path, event count, and SHA-256 anchor
  - grouped ledger event counts
  - closeout verification status
  - closeout manifest path and SHA-256 anchor
  - accepted-risk review packet reference
  - freshness state
  - known limitations
- `atlas op audit-verify` now accepts Markdown or JSON audit packets.
- JSON audit verification checks:
  - schema version
  - operation id
  - metadata-only flags
  - forbidden raw-content markers
  - operation ledger count and SHA-256 anchor
  - later archive-packet event tolerance when the recorded ledger prefix still
    matches
  - closeout manifest hash anchor
- Packet format parity docs now mark audit packets implemented and leave
  closeout manifest JSON parity as the next packet gap.
- Schema docs, command references, operator walkthroughs, roadmap, blueprint,
  trust lifecycle, and Atlas README now reflect audit JSON parity.

## Retained Evidence

- `docs/retention/releases/atlas-m87-audit-packet-json-parity.json`
- `docs/retention/releases/atlas-m87-audit-packet-json-parity.provenance.json`
- `docs/retention/production/PRODUCTION_DRY_RUN_2026-04-27_M87.md`
- Signed tag: `atlas-production-candidate-m87`

## Verified

- `bash -n tools/atlas/lib/audit.sh tools/atlas/bin/atlas`
- `git diff --check`
- `nix-shell --run 'bats tests/atlas.bats -f "atlas operation readiness reports closure blockers and ready state"'`: `1/1`
- `nix-shell --run 'bats tests/atlas.bats -f "atlas operation archive summarizes final verification state"'`: `1/1`
- `nix-shell --run 'bats tests/atlas.bats -f "atlas trust lifecycle proves operation-to-release verification chain"'`: `1/1`
- `nix-shell --run 'bats tests/atlas.bats -f "packet format parity matrix records implemented JSON and packet gaps"'`: `1/1`
- `nix-shell --run 'bats tests/atlas.bats -f "schema docs pin implemented Atlas JSON contracts"'`: `1/1`
- `nix-shell --run 'bats tests/atlas.bats -f "atlas help groups target-first workflow and story commands"'`: `1/1`
- `nix-shell --run './bin/dev-lint'`: lint ok
- `nix-shell --run './bin/dev-qa'`: `97/97`, lint ok, stress ok
- `./tools/atlas/bin/atlas v1 status --strict`: ready
- `./tools/atlas/bin/atlas release packet atlas-m87-audit-packet-json-parity --json --qa-status pass --qa-command "nix-shell --run './bin/dev-qa'" --qa-note "dev-qa passed with 97/97 tests, lint ok, and stress ok before M87 audit packet JSON parity release packet"`
- `./tools/atlas/bin/atlas release verify docs/retention/releases/atlas-m87-audit-packet-json-parity.json --commit c7dffbb1d9cf3dad429835a3dc03b8f1e312e466`: verified
- `./tools/atlas/bin/atlas release replay docs/retention/releases/atlas-m87-audit-packet-json-parity.json --skip-qa`: verified
- `git tag -v atlas-production-candidate-m87`: good signature

## Repo State

- Release commit: `c7dffbb1d9cf3dad429835a3dc03b8f1e312e466`.
- Release packet retained.
- Release provenance packet retained.
- Production dry-run note retained.
- Audit packet JSON parity is implemented and verified.
- Closeout manifest JSON parity remains the next packet-format gap.
- No production-ready claim is made.
