# Milestone 35: Atlas Release Trust JSON Schema

## Commit

`29f7adc Add Atlas release trust JSON schema`

## Purpose

Make Atlas release trust packets machine-readable while preserving the existing
Markdown release packet workflow.

## Added

- `atlas release packet --json`
- Release trust JSON schema `atlas.release_trust.v1`
- JSON release packet verification in `atlas release verify`
- JSON packet resolution by explicit path, packet name, or latest packet
- Negative verification coverage for failed JSON QA and schema mismatch

## Verified

- `bash -n tools/atlas/bin/atlas`
- `bash -n tools/atlas/lib/release.sh`
- `git diff --check`
- `nix-shell --run './bin/dev-test'`: 63/63
- `nix-shell --run './bin/dev-lint'`: lint ok
- `nix-shell --run './bin/dev-qa'`: 63/63, lint ok, stress ok

## Repo State

- implementation committed
- ready to push and tag after this retention note is committed

## Notes

Markdown remains the default release trust packet format. JSON packets carry
the same metadata-only trust record for CI gates, dashboards, future release
provenance, and other automated consumers.
