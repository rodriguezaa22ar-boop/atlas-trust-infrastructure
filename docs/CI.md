# Atlas CI Gate

## Purpose

The GitHub Actions QA workflow mirrors the local development gate for Atlas and
the native lab toolkit.

Workflow file:

```text
.github/workflows/qa.yml
```

The SLSA release-artifact workflow lives at:

```text
.github/workflows/release-slsa.yml
```

The official SLSA generic-generator workflow lives at:

```text
.github/workflows/release-slsa-generic.yml
```

## Current CI Checks

The workflow runs on pushes to `main`, pull requests targeting `main`, and
manual dispatch.

It checks:

- a full Git checkout, including tags, so retained release provenance and
  release artifact manifests can verify signed tags
- current `actions/checkout@v6` checkout plumbing to avoid the Node 20
  deprecation path for GitHub-hosted Actions
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

## SLSA Release Artifact Workflow

`release-slsa.yml` runs on manual dispatch and release-style tags. It performs
the local QA gate, checks Atlas v1 readiness, builds a source release artifact
from the exact Git commit with `git archive`, uploads the artifact/checksum,
and asks GitHub Artifact Attestations to generate SLSA build provenance through
`actions/attest@v4`. Tag-triggered runs require the tagged commit to match
`origin/main`, resolve annotated tags to their underlying Git commit, and run QA
from a local `main` branch tracking `origin/main`.

`release-slsa-generic.yml` is the `Official SLSA Generic Provenance` path. It
runs the same local QA/readiness checks, builds the same source artifact, passes
base64-encoded subject hashes to
`slsa-framework/slsa-github-generator/.github/workflows/generator_generic_slsa3.yml@v2.1.0`,
and publishes the source artifact/checksum plus official generic provenance for
release tags.

These workflows are preparation for SLSA-verifiable release artifacts. They do
not claim external SLSA certification.

The workflow is preparation for SLSA-verifiable release artifacts. It does not claim external SLSA certification.

## Future CI Gates

Future hardening can add:

- release packet smoke verification
- production dry-run artifact checks
- schema drift checks
- signed tag/provenance checks
- `gh attestation verify` policy checks for release artifacts
- `slsa-verifier verify-artifact` policy checks for official generic
  provenance
- replay verification from a clean checkout
