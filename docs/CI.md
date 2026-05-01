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

The CodeQL code scanning workflow lives at:

```text
.github/workflows/codeql.yml
```

The retained release-trust workflow lives at:

```text
.github/workflows/release-trust.yml
```

## Current CI Checks

The workflow runs on pushes to `main`, pull requests targeting `main`, and
manual dispatch.

It checks:

- a full Git checkout, including tags, so retained release provenance and
  release artifact manifests can verify signed tags
- current `actions/checkout@v6` checkout plumbing to avoid the Node 20
  deprecation path for GitHub-hosted Actions
- pull request branch context that tracks `origin/main`, so Atlas release-gate
  tests have the same upstream comparison contract they expect in local
  development
- repository whitespace with `git diff --check`
- the full local QA gate with `nix-shell --run './bin/dev-qa'`
- Atlas internal readiness with `nix-shell --run './tools/atlas/bin/atlas v1 status --strict'`
- CodeQL scanning for tracked GitHub Actions workflow YAML

`./bin/dev-qa` includes:

- Bats tests
- shell lint
- synthetic workflow stress

## Local Parity

Before pushing, run:

```bash
nix-shell --run './bin/dev-qa'
```

For `pull_request` events, GitHub checks out a merge ref. The QA workflow
creates a local branch at that checked-out commit and sets it to track
`origin/main` before running Atlas gates. That keeps release trust tests that
use upstream state aligned with the local branch workflow.

For focused checks:

```bash
git diff --check
nix-shell --run 'bats --filter "<test name>" tests/atlas.bats'
```

## Release Trust Gate

`release-trust.yml` runs on pushes to `main`, pull requests targeting `main`,
and manual dispatch. It is separate from `qa.yml` because QA answers whether
the current source tree passes the development gate, while release trust
answers whether the latest retained production-candidate evidence still
verifies.

The release-trust gate checks out full history and tags, installs Nix, locates
the latest `atlas-retention-m*` tag, and creates a temporary retained-release
worktree at that tag. Inside that retained-release worktree it verifies:

- the latest retained release packet with `atlas release verify`
- the latest retained release artifact manifest with
  `atlas release manifest-verify`
- release replay JSON with `atlas release replay --json`
- the latest production-candidate signed tag with `git tag -v`
- reviewer-readable production status with
  `atlas production status --strict --explain`

The retained-release worktree uses a synthetic
`origin/release-trust-retained` upstream reference so production status can
verify the retained evidence contract without requiring every pull request or
docs-only commit to be a new production candidate.

The release-trust workflow pins third-party GitHub Actions to immutable commit
SHAs. Human-readable comments record the upstream version tags, but mutable
tags are not the trust anchor for this retained-evidence gate.

The release-trust gate is an automated retained-evidence verification signal.
It does not claim:

- not external audit
- not certification
- not legal compliance
- not tamper-proof infrastructure
- not enterprise deployment approval
- not external SLSA certification
- not proof of runtime safety or production deployability

## Non-Goals

The QA CI gate does not claim production readiness and does not block on
`atlas production status`. Production status remains a separate local
release-promotion contract even when retained release evidence reports
`production-ready`.

The release-trust gate runs production explainability only inside the latest
retained-release worktree. It verifies retained evidence and does not certify
the active pull request or source commit as production-ready under the local
Atlas contract.

The CI gate also does not run live target assessments, external web tests, or
router/device tests.

CodeQL is used as an automated code scanning signal for tracked public source.
The workflow is scoped to `rodriguezaa22ar-boop/atlas-trust-infrastructure`
so private mirrors can skip it cleanly if repository code scanning is not
enabled there. It does not replace manual review, external audit, runtime
testing, or Atlas' own retained trust-packet verification. Shell-heavy Atlas
runtime behavior still depends on the local QA gate, shell linting, Bats
coverage, review, and retained packet verification.

JavaScript/TypeScript CodeQL analysis should be added only when the public
repository contains tracked JavaScript or TypeScript source. Until then, the
CodeQL gate intentionally covers the GitHub Actions workflow surface.

## SLSA Release Artifact Workflow

`release-slsa.yml` runs on manual dispatch and release-style tags. It is the
SLSA-verifiable release artifact candidate path. It performs the local QA gate,
checks Atlas v1 readiness, builds a source release artifact from the exact Git
commit with `git archive`, writes a checksum, writes a contents manifest, checks
the artifact for runtime-state paths and forbidden sensitive path markers,
uploads the artifact/checksum/contents metadata, and asks GitHub Artifact
Attestations to generate SLSA build provenance through `actions/attest`.
Tag-triggered runs require the tagged commit to match `origin/main`, resolve
annotated tags to their underlying Git commit, and run QA from a local `main`
branch tracking `origin/main`.

`release-slsa-generic.yml` is the `Official SLSA Generic Provenance` path. It
runs the same local QA/readiness checks, builds the same source artifact, passes
base64-encoded subject hashes to
`slsa-framework/slsa-github-generator/.github/workflows/generator_generic_slsa3.yml`,
and publishes the source artifact/checksum plus official generic provenance for
release tags.

These workflows pin third-party Actions to immutable commit SHAs. The official
SLSA generic reusable workflow is a narrow exception: the upstream generator
requires the `v2.1.0` tag ref for its internal builder validation, so Atlas
records the resolved tag commit
`f7dd8c54c2067bafc12ca7a55595d5ee9b75204a` in workflow metadata and tests the
exception explicitly. Human-readable comments record upstream version tags, but
mutable tags are not the trust anchor for normal SLSA release artifact actions.

These workflows create SLSA-verifiable release artifact candidates. They do not
claim external SLSA certification.

The workflow does not claim external SLSA certification; it produces artifacts
and metadata that a reviewer can verify with standard tooling.

GitHub Artifact Attestations are the hosted attestation mechanism for the
`release-slsa.yml` path.

## Future CI Gates

Future hardening can add:

- production dry-run artifact checks
- schema drift checks
- `gh attestation verify` policy checks for release artifacts
- `slsa-verifier verify-artifact` policy checks for official generic
  provenance
- stricter release-trust gating for externally reviewed release candidates
