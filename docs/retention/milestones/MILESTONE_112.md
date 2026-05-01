# Milestone 112: External Reviewer Package

## Commit

`9def8ac3c3e4eff76d059ecc70ff9fd710eb5718` Merge pull request #3 from rodriguezaa22ar-boop/m112-external-reviewer-package

## Purpose

Add a metadata-only external reviewer package command so Atlas can generate a
self-contained review bundle from retained public docs and latest retained
release-trust evidence.

## Added

- `atlas reviewer package <name>`
- Metadata-only reviewer package manifest:
  `atlas.external_reviewer_package.v1`
- Reviewer package documentation:
  `docs/atlas/EXTERNAL_REVIEWER_PACKAGE.md`
- Reviewer package schema:
  `docs/schemas/external-reviewer-package.v1.md`
- Docs index and command reference links
- Regression coverage for:
  - package generation
  - required docs and case-study inclusion
  - retained release packet/provenance/manifest/dry-run/milestone inclusion
  - package SHA-256 manifest generation
  - missing retained release evidence failures
  - sensitive-path exclusion
  - schema and help output coverage

## Verified

- PR #3: merged.
- Public GitHub PR QA run `25199283333`: success.
- Public GitHub PR CodeQL run `25199283341`: success.
- `git diff --check`: passed.
- Focused Bats:
  `schema docs pin|reviewer package|root README|atlas help`: 5/5.
- Focused release/reviewer Bats:
  `production status|release packet writes|release manifest indexes|release manifest verification|release replay|trust lifecycle|reviewer package|schema docs pin`: 10/10.
- `nix-shell --run './bin/dev-qa'`: 109/109, lint ok, stress ok.

## Retained Artifacts

- `docs/retention/releases/atlas-m112-external-reviewer-package.json`
- `docs/retention/releases/atlas-m112-external-reviewer-package.provenance.json`
- `docs/retention/releases/atlas-m112-external-reviewer-package.manifest.json`
- `docs/retention/production/PRODUCTION_DRY_RUN_2026-05-01_M112.md`
- Signed tag: `atlas-production-candidate-m112`

## Trust Impact

Atlas now has a generated external-review handoff surface. Reviewers can inspect
the public trust model, release trust case study, vendor payment change case
study, SLSA claim boundaries, production readiness language, retained release
packet, signed provenance, release artifact manifest, dry-run note, known
limitations, and verification commands from one metadata-only package.

## Boundaries

- This milestone does not add target-touching behavior.
- The reviewer package is a review aid, not a third-party review result.
- It does not claim external audit, certification, legal compliance, external
  SLSA certification, enterprise deployment approval, or tamper-proof
  infrastructure.
- Reviewer packages remain metadata-only and exclude secrets, credentials,
  session cookies, raw target data, raw customer data, payment data, raw
  invoices, raw contracts, packet captures, full request/response bodies, raw
  runtime artifacts, unredacted evidence bodies, and sensitive business records.
