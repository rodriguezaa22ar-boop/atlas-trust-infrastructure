# Milestone 111: Public Vendor Payment Change Case Study

## Commit

`8acaedf3fa5a64496009da04dd1a000dc31f29de` Merge pull request #2 from rodriguezaa22ar-boop/m111-vendor-payment-change-case-study

## Purpose

Add Atlas' first public business-facing case study, showing how the
metadata-first proof-chain model applies to a vendor payment change workflow
without storing sensitive financial or business records.

## Added

- Public vendor payment change case study:
  `docs/case-studies/CASE_STUDY_VENDOR_PAYMENT_CHANGE.md`.
- Docs index Case studies section linking release trust and vendor payment
  change.
- README Docs Map link for the vendor payment change case study while keeping
  the root README concise.
- Landing page Case Studies section with release trust and vendor payment
  change cards.
- Regression coverage for:
  - required vendor-payment case-study headings
  - README, docs index, and landing-page links
  - metadata-only business-flow proof positioning
  - sensitive financial and business data exclusions
  - forbidden overclaiming phrases

## Verified

- PR #2: merged.
- Public GitHub PR QA run `25195755422`: success.
- Public GitHub PR CodeQL run `25195755419`: success.
- `git diff --check`: passed.
- Focused Bats:
  `root README stays a concise landing page with dedicated docs`: 1/1.
- `nix-shell --run './bin/dev-qa'`: 107/107, lint ok, stress ok.
- `atlas release verify docs/retention/releases/atlas-m111-vendor-payment-change-case-study.json --commit 8acaedf3fa5a64496009da04dd1a000dc31f29de`:
  verified.
- `atlas release manifest-verify docs/retention/releases/atlas-m111-vendor-payment-change-case-study.manifest.json --commit 8acaedf3fa5a64496009da04dd1a000dc31f29de`:
  verified.
- `git tag -v atlas-production-candidate-m111`: good signature.

## Retained Artifacts

- `docs/retention/releases/atlas-m111-vendor-payment-change-case-study.json`
- `docs/retention/releases/atlas-m111-vendor-payment-change-case-study.provenance.json`
- `docs/retention/releases/atlas-m111-vendor-payment-change-case-study.manifest.json`
- `docs/retention/production/PRODUCTION_DRY_RUN_2026-05-01_M111.md`
- Signed tag: `atlas-production-candidate-m111`

## Trust Impact

Atlas now has two public case-study paths:

- release trust for technical reviewers, release engineers, and SLSA-aware
  teams
- vendor payment change for business owners, finance operations, risk
  reviewers, and workflow assurance readers

This strengthens the public thesis that Atlas is metadata-first operational
trust infrastructure, not only a security workflow tool.

## Boundaries

- This milestone does not add or change Atlas runtime target-touching behavior.
- The case study does not claim fraud prevention, payment approval, external
  audit, legal compliance, certification, tamper-proof infrastructure, or bank
  control validation.
- Atlas does not replace accounting software, bank portals, approval tools,
  email, document storage, GRC, fraud detection, legal review, or compliance
  review.
- Vendor payment change proof remains metadata-only and excludes sensitive
  financial records, credentials, tokens, private keys, raw invoices, raw
  contracts, private business records, and unredacted emails.
