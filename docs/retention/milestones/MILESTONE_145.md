# Milestone 145: Generic Event Adapter Quickstart

## Commit

`5c5a90e4929b53a2c76334808f9b7b3874d404fb` M145 add generic event adapter quickstart

## Pull Request

PR #46

## Purpose

Make the `generic.external_event.v1` import-only receipt adapter tryable by an
outside reviewer in under five minutes.

## Added

- Added `docs/TRY_GENERIC_EVENT_ADAPTER.md` with copy-paste local import,
  receipt verify, and linked receipt replay commands.
- Added expected text and JSON replay output for the generated synthetic
  adapter receipts.
- Linked the quickstart from the root `README.md` and `docs/INDEX.md`.
- Added focused Bats coverage that executes the quickstart path against the
  synthetic example events.
- Preserved explicit metadata-only, raw-artifact, known-limitations, and
  non-guarantee language.

## Validation

- CodeQL: passed.
- Nix QA: passed.
- Release Trust: passed.
- GitHub Actions workflow analysis: passed.
- Builder pre-merge focused M143/M144/M145 generic adapter Bats: passed, 3/3.
- Builder pre-merge `./bin/export-public-trust --check`: passed.
- Builder pre-merge `nix-shell --run './bin/dev-qa'`: passed with 137/137
  Bats plus lint, capabilities, adapters, policy, approval, evidence,
  portability, and stress.
- Builder post-merge `nix-shell --run './bin/dev-qa'`: passed with 137/137
  Bats plus lint, portability, and stress.

## Trust Impact

M145 turns the first import-only adapter into a reviewer-tryable path without
expanding the adapter surface. Reviewers can import synthetic local event
metadata, verify the generated receipt, and replay a linked chain while the
adapter remains local-file-only and non-authoritative.

## Boundaries

- Docs and tests only.
- No runtime behavior changed.
- No adapter behavior changed.
- No receipt semantics changed.
- No second adapter added.
- No network behavior, action execution, database, server, web UI, hidden
  state, production claim, or live integration added.
- `metadata_only=true` preserved.
- `raw_artifacts_embedded=false` preserved.
- `known_limitations` required and visible.
- Non-guarantee language preserved.
- AI agents, source systems, scanners, and webhooks remain event sources only,
  not authorities or execution engines.
- Tag target: `atlas-retention-m145`.
