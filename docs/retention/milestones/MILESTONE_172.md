# Milestone 172: Capability Manifest Draft

## Reviewed Commit

`3cf9918ee0a5b8b094f8f38ff55d1e9338818f60` M171 scale and storage safety
regression

## Purpose

Draft the next machine-readable Atlas capability manifest layer so Atlas can
map recognized actions to capability class, approval posture, emitted evidence,
and blocked-action boundaries before adding runtime enforcement.

M172 is the value step after the M171 scale/storage safety hardening step.

## Added

- Expanded `capabilities.yaml` with draft governance actions for receipts,
  generic event import, policy evaluation, approval request metadata, release
  packet creation, reviewer package generation, and evidence sufficiency
  review.
- Added `docs/governance/CAPABILITY_MANIFEST_M172.md`.
- Added focused Bats coverage for the M172 manifest draft and blocked-action
  boundaries.
- Updated the docs index and milestone index.

## Validation

- `git diff --check`: pass.
- `./bin/dev-capabilities`: pass.
- Focused M172 capability manifest Bats: pass.
- `./bin/export-public-trust --check`: pass.
- `nix-shell --run './bin/dev-qa'`: pass.

## Boundaries

- Docs/schema/tests only.
- No Atlas runtime enforcement added.
- No adapter execution added.
- No policy engine changed.
- No live integration added.
- No GitHub API calls added.
- No webhook server added.
- No network collector added.
- No database/server/web UI added.
- No hidden state added.
- No receipt semantic changes.
- No new authority claims.
- Known limitations preserved.
- Tag target: `atlas-retention-m172`.
