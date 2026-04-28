# Atlas CI Gate

## Purpose

The GitHub Actions QA workflow mirrors the local development gate for Atlas and
the native lab toolkit.

Workflow file:

```text
.github/workflows/qa.yml
```

## Current CI Checks

The workflow runs on pushes to `main`, pull requests targeting `main`, and
manual dispatch.

It checks:

- a full Git checkout, including tags, so retained release provenance and
  release artifact manifests can verify signed tags
- repository whitespace with `git diff --check`
- the full local QA gate with `nix-shell --run './bin/dev-qa'`
- Atlas internal readiness with `nix-shell --run './tools/atlas/bin/atlas v1 status --strict'`

`./bin/dev-qa` includes:

- Bats tests
- shell lint
- synthetic workflow stress

## Local Parity

Before pushing, run:

```bash
nix-shell --run './bin/dev-qa'
```

For focused checks:

```bash
git diff --check
nix-shell --run 'bats --filter "<test name>" tests/atlas.bats'
```

## Non-Goals

The current CI gate does not claim production readiness and does not yet block
on `atlas production status`. Production status remains a separate local
release-promotion contract even when retained release evidence reports
`production-ready`.

The CI gate also does not run live target assessments, external web tests, or
router/device tests.

## Future CI Gates

Future hardening can add:

- release packet smoke verification
- production dry-run artifact checks
- schema drift checks
- signed tag/provenance checks
- replay verification from a clean checkout
