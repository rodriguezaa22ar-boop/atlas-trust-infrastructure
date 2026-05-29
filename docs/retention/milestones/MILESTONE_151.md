# Milestone 151: GitHub Actions Run Receipt Candidate

## Reviewed Commit

`1a80a80439a08c41e34d87c3e8f1bdef1ecc4a3e` M150 retained checkpoint

## Purpose

Add the first real-world import-only event candidate by representing GitHub
Actions workflow run and check run metadata as local
`generic.external_event.v1` files.

## Added

- Added metadata-only GitHub Actions workflow run and check run examples under
  `examples/adapters/generic-external-event/`.
- Added `docs/reviews/GITHUB_ACTIONS_RUN_RECEIPT_CANDIDATE_M151.md`.
- Updated `docs/INDEX.md`.
- Updated `docs/retention/MILESTONE_INDEX.md`.
- Added focused Bats coverage proving the examples import, verify, and replay
  as a linked receipt chain with no hidden runtime directories.

## Validation

- Atlas Node pre-check: Current State Ready, 0 blockers, 0 warnings; W012
  self-test passed, 25/25.
- Direct local CLI smoke: import/verify/replay passed for the linked GitHub
  Actions workflow run/check receipts.
- `git diff --check`: pass.
- Focused M151 Bats: pass, 1/1.
- `./bin/export-public-trust --check`: pass, Allowed files 514, Forbidden
  paths 0, Private markers 0.
- `nix-shell --run './bin/dev-qa'`: pass, 143/143 Bats plus lint,
  capabilities, adapters, policy, approval, evidence, portability, and stress;
  `qa: ok`.

## Trust Impact

M151 moves the generic external event adapter from synthetic and AI-agent
examples to the first representative real-world event shape while preserving
the same import-only, metadata-only, verifier-only boundary.

The candidate shows that GitHub Actions run/check metadata can become
verifiable Atlas receipts without making Atlas a GitHub client, webhook
collector, action runner, approval authority, or source-system truth engine.

## Boundaries

- Local file input only.
- Metadata-only examples only.
- Existing `generic.external_event.v1` adapter only.
- No GitHub API calls.
- No webhook server.
- No network collector.
- No action execution.
- No action rerun, cancellation, approval, or dispatch behavior.
- No database.
- No server or web UI.
- No new adapter runtime.
- No hidden state.
- No production claim.
- No receipt semantics changed.
- No receipt verification, replay, canonicalization, release, or reviewer gate
  weakened.
- No raw workflow logs, check annotations, webhook payloads, credentials, or
  secrets embedded.
- GitHub Actions events are event sources only.
- Atlas remains verifier, not authority.
- Human and policy remain authority.
- Generated GitHub Actions candidate receipts verify.
- Linked GitHub Actions candidate receipts replay.
- `metadata_only=true` preserved.
- `raw_artifacts_embedded=false` preserved.
- Tag target: `atlas-retention-m151`.
