# Milestone 105: GitHub Actions Checkout Hardening

## Commit

`bfbcb8e7a0583f5534ea8dd232d4a7170e733553` Update GitHub Actions checkout pins

## Purpose

Remove the GitHub Actions Node 20 deprecation warning from Atlas' QA and
release-trust workflows by moving checkout plumbing to the current
`actions/checkout@v6` path.

## Added

- Updated `.github/workflows/qa.yml` to use `actions/checkout@v6`.
- Updated `.github/workflows/release-slsa.yml` to use `actions/checkout@v6`.
- Updated `.github/workflows/release-slsa-generic.yml` to use
  `actions/checkout@v6`.
- Updated CI documentation to record the checkout hardening.
- Updated workflow regression tests so Atlas continues to assert full-history
  checkouts with tags and the current checkout action.

## Verified

- GitHub API latest release check:
  `gh api repos/actions/checkout/releases/latest --jq .tag_name`: `v6.0.2`.
- `git diff --check`: passed.
- focused Bats:
  `ci workflow mirrors local Atlas QA gate` and
  `official SLSA generic workflow and claim docs define external verification path`:
  2/2.
- `nix-shell --run './bin/dev-qa'`: 107/107, lint ok, stress ok.

## Trust Impact

Atlas' local QA, release artifact, GitHub attestation, and official SLSA
generic-generator workflows now avoid a known GitHub-hosted Actions deprecation
path while preserving full-history checkout behavior needed for signed tags,
release manifests, provenance references, and replay checks.

## Boundaries

- This milestone does not change Atlas runtime command behavior.
- This milestone does not claim external SLSA certification or independent
  audit completion.
- Release workflows still need tag-triggered GitHub runs to prove each future
  release artifact and provenance packet.
