# Milestone 143: Generic External Event Receipt Adapter

## Commit

`70860719aa6348c0ff293c710cf29292c516dae2` M143 add generic external event receipt adapter

## Pull Request

PR #42

## Purpose

Add the first import-only receipt adapter so Atlas can convert one synthetic
external event shape into an `atlas.receipt.v1` receipt without becoming an
action engine.

## Added

- Added `generic.external_event.v1` as a local-file event input contract.
- Added `atlas receipt import-generic-event`.
- Added synthetic minimal and approval external-event examples.
- Added adapter documentation for the import-only boundary.
- Added focused Bats coverage for valid import, linked replay, unsafe input
  rejection, and no runtime directory mutation.
- Tightened receipt forbidden-content detection for `raw_request` and
  `raw_response` markers.

## Validation

- CodeQL: passed.
- Nix QA: passed.
- Release Trust: passed.
- GitHub Actions workflow analysis: passed.
- Builder post-merge `nix-shell --run './bin/dev-qa'`: passed with 135/135
  Bats plus lint, portability, and stress.

## Trust Impact

M143 proves Atlas can import a small external metadata shape into the receipt
core while preserving the receipt verifier, replay, canonicalization, and
release/reviewer gates. It keeps Atlas as the proof layer around existing
systems rather than making Atlas an execution engine or integration runtime.

## Boundaries

- Import-only.
- Local file input only.
- No network calls.
- No action execution.
- No hidden runtime state.
- Writes only the requested receipt output.
- Preserves `metadata_only=true`.
- Preserves `raw_artifacts_embedded=false`.
- Requires `known_limitations`.
- Does not add live GitHub, scanner, ticketing, cloud, webhook, server,
  database, web UI, agent, or demo-site behavior.
- Does not claim source-system truth, source-system availability, human intent,
  legal compliance, artifact correctness, authorization, production readiness,
  external audit, or certification.
- Tag target: `atlas-retention-m143`.
