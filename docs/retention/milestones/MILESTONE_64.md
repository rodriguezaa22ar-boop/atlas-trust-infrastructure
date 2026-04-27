# Milestone 64: Atlas CI QA Gate

## Commit

`d282cae99723bce1d3a51eb7cc0d8f902a763cd0` Add Atlas CI QA gate

## Purpose

Move the local Atlas QA gate into a repository-level GitHub Actions workflow.

## Added

- `.github/workflows/qa.yml`.
- `docs/CI.md`.
- README, roadmap, and blueprint updates.
- Bats coverage preserving workflow triggers, Nix setup, local QA parity, v1
  readiness gate, and production-readiness non-goal.

## CI Gate

The workflow runs on pushes to `main`, pull requests targeting `main`, and
manual dispatch.

It checks:

- `git diff --check`
- `nix-shell --run './bin/dev-qa'`
- `nix-shell --run './tools/atlas/bin/atlas v1 status --strict'`

## Non-Goal

The workflow does not gate on `atlas production status` yet because production
readiness is expected to remain blocked until signing/provenance, retained
production dry-run evidence, and a current verified release trust packet exist.

## Verified

- `git diff --check`
- `nix-shell --run 'bats --filter "ci workflow" tests/atlas.bats'`: `1/1`
- `nix-shell --run './bin/dev-qa'`: `81/81`, lint ok, stress ok

## Repo State

- Implementation committed at `d282cae99723bce1d3a51eb7cc0d8f902a763cd0`.
- Retention note present.
- Index updated through Milestone 64.
- Tag target: `atlas-retention-m64`.
