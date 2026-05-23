# Milestone 144: Generic Event Adapter Security Regressions

## Commit

`466b8297e482d9a0283e5ce8fd71dcebac13fb99` M144 add generic event adapter security regressions

## Pull Request

PR #44

## Purpose

Attack-test the `generic.external_event.v1` import-only receipt adapter before
adding any second adapter.

## Added

- Added focused security regression coverage for missing `known_limitations`.
- Added regression coverage for `metadata_only=false`.
- Added regression coverage for `raw_artifacts_embedded=true`.
- Added regression coverage for `raw_request` and `raw_response`.
- Added regression coverage for secret markers and `Authorization: Bearer`
  markers.
- Added regression coverage for embedded raw artifact fields and malformed
  artifact refs.
- Added checks that rejected imports do not create output receipts.
- Added checks that successful imports write only the requested receipt output,
  do not create hidden runtime directories, verify, and replay as a linked
  receipt chain.

## Validation

- CodeQL: passed.
- Nix QA: passed.
- Release Trust: passed.
- GitHub Actions workflow analysis: passed.
- Builder post-merge `nix-shell --run './bin/dev-qa'`: passed with 136/136
  Bats plus lint, portability, and stress.

## Trust Impact

M144 confirms the first executable import-only adapter fails closed under
unsafe event shapes without requiring runtime changes. It preserves the pattern
of building a trust surface, retaining it, then attack-testing the boundary
before expanding Atlas to any second adapter.

## Boundaries

- Tests only.
- No adapter/runtime code changes.
- Unsafe inputs fail closed.
- Rejected imports do not create output receipts.
- Successful import writes only the requested receipt output.
- No hidden runtime directories are created.
- Generated receipts verify.
- Linked generated receipts replay.
- No network behavior, action execution, database, server, web UI, hidden
  state, production claim, or second adapter added.
- Tag target: `atlas-retention-m144`.
