# Milestone 108: CodeQL Code Scanning Gate

## Commit

`fc2799acbd96fd7bbafe331756d1893c77eaf170` Add CodeQL code scanning gate

## Purpose

Add GitHub-native CodeQL code scanning as a public automated review signal
without changing Atlas runtime behavior or claiming external audit coverage.

## Added

- `.github/workflows/codeql.yml` with CodeQL v4 scanning for GitHub Actions
  workflow YAML and JavaScript/TypeScript-compatible public source.
- Scheduled, push, pull request, and manual CodeQL triggers.
- Public-repository guard so private mirrors can skip CodeQL cleanly if code
  scanning is not enabled there.
- README, CI, and security-policy wording that frames CodeQL as an automated
  code scanning signal, not a replacement for manual review, external audit,
  runtime testing, or Atlas' retained trust-packet verification.
- Regression coverage pinning the workflow, scoped repository guard, public
  code-scanning language, and non-overclaiming documentation.

## Verified

- Focused Bats:
  `ci workflow mirrors local Atlas QA gate`: 1/1.
- `git diff --check`: passed.
- `nix-shell --run './bin/dev-qa'`: 107/107, lint ok, stress ok.
- `atlas release verify docs/retention/releases/atlas-m108-codeql-code-scanning.json --commit fc2799acbd96fd7bbafe331756d1893c77eaf170`:
  verified.
- `atlas release manifest-verify docs/retention/releases/atlas-m108-codeql-code-scanning.manifest.json --commit fc2799acbd96fd7bbafe331756d1893c77eaf170`:
  verified.

## Trust Impact

Atlas now has a GitHub-native public code scanning gate in addition to local
QA, shell linting, Bats coverage, SLSA-verifiable release artifacts, retained
release packets, signed provenance, release manifests, and production status.
This improves public trust hardening without weakening the metadata-only or
local-contract boundaries.

## Boundaries

- CodeQL is not an external audit, SLSA certification, enterprise
  certification, or deployment approval.
- CodeQL does not cover every shell runtime behavior; Atlas still depends on
  local QA, shell linting, Bats coverage, review, and retained packet
  verification.
- The workflow is scoped to the public `atlas-trust-infrastructure` repository
  so private mirrors can skip it cleanly.
