# Milestone 152: GitHub Actions Event Security Regression

## Reviewed Commit

`38904ed1d837e7786e1014483c51ddca6e30e8a8` M151 merged checkpoint

## Purpose

Prove the GitHub Actions run/check receipt candidate fails closed against
unsafe CI metadata while staying local-file import only.

## Added

- Added focused security regression coverage for GitHub Actions
  `generic.external_event.v1` imports.
- Added rejection coverage for GitHub token marker rejected,
  Authorization/Bearer markers, and webhook secret marker rejected.
- Added rejection coverage for raw_logs rejected, raw_job_output rejected,
  raw_workflow_output rejected, `raw_request`, and `raw_response`.
- Added rejection coverage for environment secret fields and private-key
  markers.
- Added rejection coverage for `metadata_only=false`,
  `raw_artifacts_embedded=true`, missing `known_limitations`, and malformed
  artifact references.
- Added rejection coverage for missing GitHub Actions repository, workflow,
  run, and check identity references.
- Added checks that rejected imports do not create output receipts.
- Verified successful GitHub Actions run/check imports write only the requested
  receipt output, generated receipts verify, linked receipts replay, and no
  hidden runtime directories are created.
- Narrowly hardened generic event import validation for GitHub Actions
  token-shaped markers, raw CI output keys, environment secret keys, and
  required GitHub Actions run/check identity references.

## Validation

- Atlas Node pre-check: Current State Ready, 0 blockers, 0 warnings; W012
  self-test passed, 25/25.
- `git diff --check`: pass.
- `bash -n tools/atlas/lib/receipt.sh`: pass.
- Focused M152 Bats: pass, 1/1.
- Focused M143/M144/M148/M151/M152 Bats: pass, 5/5.
- `./bin/export-public-trust --check`: pass, Allowed files 515, Forbidden
  paths 0, Private markers 0.
- `nix-shell --run './bin/dev-qa'`: pass, 144/144 Bats plus lint,
  capabilities, adapters, policy, approval, evidence, portability, and stress;
  `qa: ok`.

## Trust Impact

M152 attack-tests the first representative real-world event candidate before
any live GitHub integration or second real-world source is added.

The regression keeps GitHub Actions events as metadata-only event sources.
Atlas remains a receipt verifier, not a GitHub client, webhook collector,
action runner, approval authority, or source-system truth engine.

## Boundaries

- Tests-first security regression with narrow runtime hardening for discovered
  fail-closed gaps.
- Local file input only.
- Existing `generic.external_event.v1` adapter only.
- No GitHub API calls.
- No webhook server.
- No network collector.
- No action execution.
- No database.
- No server or web UI.
- No new adapter.
- No hidden state.
- No production claim.
- No receipt verification, replay, canonicalization, release, or reviewer gate
  weakened.
- GitHub Actions events are event sources only.
- Atlas remains verifier, not authority.
- Human and policy remain authority.
- Unsafe GitHub Actions event inputs fail closed.
- GitHub token-shaped markers fail closed.
- Raw CI output keys fail closed.
- Missing GitHub Actions run/check identity references fail closed.
- Rejected imports create no output receipts.
- Valid GitHub Actions run/check receipts verify.
- Linked GitHub Actions receipts replay.
- `metadata_only=true` preserved.
- `raw_artifacts_embedded=false` preserved.
- Tag target: `atlas-retention-m152`.
