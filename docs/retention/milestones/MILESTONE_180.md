# Milestone 180: Evidence Envelope Schema Draft

## Reviewed Commit

`81e9b543177e11bdb7e5c868469b1781defd4f08` M179 approval plane safety regression

## Purpose

Define the first Atlas evidence-envelope schema draft for the shared
metadata-only record shape future capability, adapter, policy, approval,
workflow, and receipt decisions can emit.

M180 is the value step after the M179 approval-plane safety lock.

## Added

- Added `evidence/schemas/evidence-envelope.v1.schema.json`.
- Added metadata-only examples for minimal, policy decision, adapter event,
  approval event, AI-agent action, and release verification envelopes.
- Added the M180 evidence-envelope governance document.
- Added the stable evidence-plane entry point.
- Extended `bin/dev-evidence` to validate the M180 schema and examples while
  preserving existing evidence verifier checks.
- Added focused Bats coverage for the M180 evidence-envelope schema draft.
- Updated the documentation index, milestone index, and public export
  manifest.

## Safety Result

- M180 does not add runtime evidence collection.
- M180 does not add automatic evidence capture.
- M180 does not add an evidence collector, evidence lake, database, server,
  web UI, live integration, credentials, API calls, webhooks, or network
  collectors.
- M180 does not add adapter execution, policy enforcement, or approval
  execution.
- M180 does not change receipt semantics, hashing, canonicalization, or replay
  behavior.
- Evidence examples remain metadata-only and exclude raw artifacts.
- AI-agent examples treat agents as requesters, not authorities.
- Release verification examples remain read-only.
- Business-flow guidance forbids private business data and payment data
  embedding.

## Validation

- `git diff --check`: pass.
- `bash -n bin/dev-evidence`: pass.
- `./bin/dev-evidence`: pass.
- `./bin/dev-governance`: pass.
- Focused M180 evidence envelope Bats: pass.
- `./bin/export-public-trust --check`: pass.
- `nix-shell --run './bin/dev-qa'`: pass.

## Boundaries

- Docs/tests/schema/examples only.
- No runtime evidence engine added.
- No evidence collector added.
- No live integration added.
- No credential handling added.
- No API calls added.
- No webhooks added.
- No network collectors added.
- No database/server/web UI added.
- No policy engine execution added.
- No approval engine execution added.
- No adapter execution added.
- No receipt semantics changed.
- No automatic evidence capture added.
- No raw artifact preservation added.
- Known limitations preserved.
- Tag target: `atlas-retention-m180`.
