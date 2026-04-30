# Milestone 107: Public Identity and Claim Discipline

## Commit

`1ff2a82b9f9b8d1c71a41e985e8dd94ba82be0d8` Tighten public Atlas identity and claim language

## Purpose

Resolve the public-facing identity and claim-discipline gaps identified in the
professional repository review without expanding Atlas runtime scope.

## Added

- Root README now leads with `Atlas Trust Infrastructure` instead of `Native
  Lab Toolkit`.
- README now states the public repository purpose and distinguishes the private
  `atlas-lab-toolkit` implementation home from the public explanation surface.
- README and docs index now include a role-based start path for new readers,
  operators, business owners, release reviewers, SLSA reviewers, contributors,
  and security reporters.
- Public landing page now states above the fold that Atlas does not replace
  scanners or automate exploitation.
- SLSA claim documentation now includes a claim matrix mapping claim,
  required evidence, verification command, and non-claim.
- Regression tests now pin the public identity, role-based docs route, landing
  page boundary language, and SLSA claim matrix.

## Verified

- Focused Bats:
  `root README stays a concise landing page with dedicated docs`,
  `official SLSA generic workflow and claim docs define external verification
  path`, and
  `independent review packet makes v0.4.0-rc1 externally reviewable without
  overclaiming`: 3/3.
- `git diff --check`: passed.
- `atlas v1 status --strict --json`: ready, blocked 0, warning 0.
- `nix-shell --run './bin/dev-qa'`: 107/107, lint ok, stress ok.
- `atlas release verify docs/retention/releases/atlas-m107-public-identity-claim-discipline.json --commit 1ff2a82b9f9b8d1c71a41e985e8dd94ba82be0d8`:
  verified.
- `atlas release manifest-verify docs/retention/releases/atlas-m107-public-identity-claim-discipline.manifest.json --commit 1ff2a82b9f9b8d1c71a41e985e8dd94ba82be0d8`:
  verified.

## Trust Impact

Atlas' public explanation now matches the repository name and landing page, and
SLSA language is gated by explicit evidence and non-claims. This improves
external legibility without weakening the metadata-only, authorized-use, and
local-contract boundaries.

## Boundaries

- This milestone is documentation and public-positioning hardening; it does not
  add new runtime target-touching behavior.
- The SLSA matrix does not claim external SLSA certification, legal
  certification, enterprise certification, or deployment approval.
- `production-ready` remains bounded to the local Atlas contract.
