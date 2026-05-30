# Milestone 159: Evidence Sufficiency Regression

## Reviewed Commit

`6b3a559fe0c60d601cb00b1b0ce456e49085f8ad` M158 merged checkpoint

## Purpose

Protect the M158 evidence sufficiency report from implying sufficiency when
required evidence is `missing`, `stale`, `unverifiable`, or outside Atlas'
claim boundary.

M159 is the hardening step after the M158 value step. It keeps evidence
sufficiency review useful by requiring gaps to remain visible as follow-up,
refresh, remediation, acceptance, or outside-Atlas determination work.

## Added

- Added focused Bats regression coverage for the M158 evidence sufficiency
  report and related control mapping.
- Verified that `missing`, `stale`, and `unverifiable` evidence remains tied
  to reviewer follow-up and is not treated as sufficient by Atlas.
- Verified that evidence sufficiency language does not drift into approval,
  certification, compliance, deployability, external audit, legal compliance,
  or runtime safety claims.
- Updated the milestone index with the M159 retention entry.

## Validation

- `git diff --check`: pass.
- Focused M159 evidence sufficiency regression Bats: pass.
- `./bin/export-public-trust --check`: pass, 532 allowed files, 0 forbidden
  paths, 0 private markers.
- `nix-shell --run './bin/dev-qa'`: pass, 151/151 Bats plus lint,
  governance, adapters, policy, approval, evidence, portability, and stress;
  qa ok.

## Trust Impact

M159 preserves the positive M158 claim:

```text
Atlas supports evidence sufficiency review by mapping required evidence to
present, missing, stale, or unverifiable status with local verification paths
and reviewer follow-up.
```

The regression protects the boundary that Atlas reports proof-envelope status
and local verification paths. Reviewers, auditors, approvers, or authorities
still decide whether gaps block the objective, require remediation, or can be
accepted as residual risk.

## Boundaries

- Docs/tests only.
- No Atlas runtime behavior changed.
- No receipt semantics changed.
- No new adapter.
- No live integration.
- No network collector.
- No database, server, or web UI.
- No QA, Release Trust, CodeQL, workflow analysis, production status, release
  verify, release replay, reviewer package, or public export gate weakened.
- No certification, external audit completion, legal compliance,
  tamper-proof infrastructure, guaranteed safety, external SLSA certification,
  runtime safety, or production deployability claim added.
- Tag target: `atlas-retention-m159`.
