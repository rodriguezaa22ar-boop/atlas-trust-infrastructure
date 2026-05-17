# Milestone 134: Receipt Security Regression Suite

## Commit

`2ff24ebcbb760c1f1dba8a7332936cd3223e613f` M134 add receipt security regression tests

## Purpose

Prove Atlas receipt verification and receipt replay fail safely against unsafe
receipt content, hash tampering, chain tampering, and read-only mutation.

## Added

- Added focused Bats regression coverage for secret marker rejection
- Added rejection coverage for raw request and response body fields
- Added rejection coverage for embedded raw artifact fields
- Added rejection coverage for `metadata_only=false`
- Added rejection coverage for `raw_artifacts_embedded=true`
- Added rejection coverage for missing `known_limitations`
- Added event-hash tampering coverage for `atlas receipt verify`
- Added `prev_hash` chain tampering coverage for `atlas receipt replay`
- Added receipt verify and receipt replay read-only mutation checks
- Added verifier-output coverage for retained non-guarantee language

## Validation

- PR #28: merged.
- Public GitHub PR QA: success.
- Public GitHub PR CodeQL: success.
- Public GitHub PR Release Trust: success.
- Public GitHub workflow analysis: success.
- `git diff --check`: passed.
- Focused receipt Bats regression filter: passed.
- Builder `nix-shell --run './bin/dev-qa'`: passed with 128/128 Bats plus
  lint, portability, and stress.
- Post-merge builder focused receipt/docs Bats filter: passed.

## Trust Impact

M134 is the enforcement side of the receipt trust loop. It does not add new
receipt features. It proves the current receipt and replay boundaries reject
unsafe cases that would weaken metadata-only receipts, replayable hashes,
reviewer-safe output, or read-only command behavior.

## Boundaries

- This milestone is tests-only.
- This milestone does not change receipt semantics.
- This milestone does not add runtime state.
- This milestone does not add scanners, collectors, servers, automation
  runners, exploit workflows, credential workflows, fuzzing workflows, or
  denial-of-service workflows.
- Receipt verification and replay remain local-only, metadata-only, and
  reviewer-safe.
- Tag target: `atlas-retention-m134`.
