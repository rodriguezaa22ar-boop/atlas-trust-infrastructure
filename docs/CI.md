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

The current CI gate does not claim production readiness. It does not yet block
on `atlas production status`, because production readiness is expected to remain
`not-ready` until signing/provenance, retained production dry-run evidence, and
a current verified release trust packet are in place.

The CI gate also does not run live target assessments, external web tests, or
router/device tests.

## Future CI Gates

Future hardening can add:

- release packet smoke verification
- production dry-run artifact checks
- schema drift checks
- signed tag/provenance checks
- replay verification from a clean checkout
