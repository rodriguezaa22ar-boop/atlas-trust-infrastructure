# Milestone 67: Atlas Signed Release Provenance

## Release Commit

`3e2a8b734fed694b350c4916c242c5e2ffd80e76` Verify release provenance with retained public key

## Purpose

Make the production signing/provenance gate real by binding a retained release
trust packet to a verified signed Git tag and a retained public key.

## Added

- `atlas production status` signing/provenance verification.
- `atlas.release_provenance.v1` schema contract.
- Retained public-key verification in a temporary keyring.
- Release packet SHA-256 verification from provenance.
- Signed tag target verification.
- Release packet replay from the provenance gate.
- Release packet discovery that ignores `*.provenance.json`.
- `gnupg` in the Nix development shell.
- Tests proving production status can fail before provenance and pass after
  signed provenance, retained public key, release packet, and dry-run evidence
  exist together.

## Retained Evidence

- `docs/retention/releases/atlas-m67-production-candidate.json`
- `docs/retention/releases/atlas-m67-production-candidate.provenance.json`
- `docs/retention/releases/atlas-m67-release-signing-public-key.asc`
- `docs/retention/production/PRODUCTION_DRY_RUN_2026-04-27_M67.md`
- Signed tag: `atlas-production-candidate-m67`

The retained public key is safe to commit. The private signing key remains in
the local GPG keyring and is not part of the repository.

## Verified

- `bash -n tools/atlas/lib/production.sh tools/atlas/lib/release.sh`
- `git diff --check`
- `nix-shell --run 'bats --filter "production status" tests/atlas.bats'`: `1/1`
- `nix-shell --run 'bats --filter "schema docs|packet format parity" tests/atlas.bats'`: `2/2`
- `nix-shell --run 'bats --filter "external legibility|production status|schema docs|packet format parity" tests/atlas.bats'`: `4/4`
- `nix-shell --run './bin/dev-lint'`: lint ok
- `nix-shell --run './bin/dev-qa'`: `81/81`, lint ok, stress ok
- `./tools/atlas/bin/atlas release packet atlas-m67-production-candidate --json --qa-status pass --qa-note "dev-qa passed before M67 signed provenance packet"`
- `git tag -v atlas-production-candidate-m67`: good signature
- `./tools/atlas/bin/atlas release verify docs/retention/releases/atlas-m67-production-candidate.json --commit 3e2a8b734fed694b350c4916c242c5e2ffd80e76`: verified

## Repo State

- Release commit: `3e2a8b734fed694b350c4916c242c5e2ffd80e76`.
- Release packet retained.
- Release provenance packet retained.
- Release signing public key retained.
- Production dry-run note retained.
- Production readiness remains a local contract, not an external audit or
  deployment certification.
