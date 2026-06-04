# Milestone 173: Capability Manifest Safety Regression

## Reviewed Commit

`2fd717405a42efae7d7775cfc1ae204c9a50d4fa` M172 capability manifest draft

## Purpose

Protect the M172 capability manifest draft from implying runtime enforcement,
authorization authority, adapter execution, policy execution, compliance,
certification, production governance readiness, or live integration before
those capabilities exist.

M173 is the hardening step after the M172 capability manifest value step.

## Added

- Added focused Bats coverage for capability manifest structure, default-deny
  posture, approval-aware mutating and bounded execution capabilities, and
  metadata-only evidence outputs.
- Added focused regression coverage for manifest contract boundaries:
  governance draft status, no runtime enforcement, no authorization grant, no
  adapter execution, and no live integrations.
- Added no-overclaim coverage for compliance, certification, external audit,
  production deployability, runtime safety, model correctness, complete event
  coverage, adapter execution authority, and policy enforcement claims.
- Tightened the M172 capability manifest wording around M173, authorization,
  policy/approval execution, live integrations, metadata-only evidence, and
  business/trust value.
- Updated the milestone index with the M173 retention entry.

## Validation

- `git diff --check`: pass.
- `./bin/dev-capabilities`: pass.
- Focused M173 capability manifest safety Bats: pass.
- `./bin/export-public-trust --check`: pass.
- `nix-shell --run './bin/dev-qa'`: pass.

## Safety Result

M173 keeps the capability manifest useful and positive while preserving
default-deny governance, operator control, metadata-only evidence, and the
boundary that the manifest is a contract draft unless later runtime enforcement
is explicitly added.

## Boundaries

- Docs/tests only.
- No Atlas runtime behavior changed.
- No receipt semantics changed.
- No adapter execution added.
- No policy engine added.
- No approval engine added.
- No live integration added.
- No GitHub API calls added.
- No webhook server added.
- No network collector added.
- No database/server/web UI added.
- No hidden state added.
- No QA, Release Trust, CodeQL, workflow analysis, production status, release
  verify, release replay, reviewer package, public export, receipt verify,
  receipt replay, or canonicalization gate weakened.
- Known limitations preserved.
- Tag target: `atlas-retention-m173`.
