# Milestone 68: Atlas README Landing Page Split

## Release Commit

`adc5cf3afcb734f1d106f26de04d9083057a9bbc` Refocus README as Atlas landing page

## Purpose

Make the root README useful as a five-minute reviewer landing page while
moving heavy command and workflow material into dedicated documentation.

## Added

- Short root `README.md` with identity, quick start, safety boundary, current
  maturity, top 10 commands, docs map, layout, and development notes.
- `docs/COMMAND_REFERENCE.md` for the full command surface.
- `docs/TRUST_LIFECYCLE.md` for the scope-to-release trust chain.
- `docs/OPERATOR_GUIDE.md` for end-to-end operator flow.
- `docs/RELEASE_TRUST.md` for release packet, verify, replay, signing, and
  provenance.
- `docs/WEB_ASSESSMENT.md` for the `atlas web assess` workflow.
- README split regression coverage in `tests/atlas.bats`.
- Stale readiness wording cleanup in Atlas trust lifecycle and v1 readiness
  docs after signed release provenance became available.

## Retained Evidence

- `docs/retention/releases/atlas-m68-readme-landing.json`
- `docs/retention/releases/atlas-m68-readme-landing.provenance.json`
- `docs/retention/production/PRODUCTION_DRY_RUN_2026-04-27_M68.md`
- Signed tag: `atlas-production-candidate-m68`

The M68 provenance packet reuses the retained M67 public key because the same
local Atlas release signing key signed the M68 release candidate tag.

## Verified

- `git diff --check`
- `nix-shell --run 'bats --filter "README|demo walkthrough|external legibility" tests/atlas.bats'`: `3/3`
- `nix-shell --run './bin/dev-qa'`: `82/82`, lint ok, stress ok
- `./tools/atlas/bin/atlas release packet atlas-m68-readme-landing --json --qa-status pass --qa-note "dev-qa passed before M68 README landing release packet"`
- `git tag -v atlas-production-candidate-m68`: good signature

## Repo State

- Release commit: `adc5cf3afcb734f1d106f26de04d9083057a9bbc`.
- Release packet retained.
- Release provenance packet retained.
- Production dry-run note retained.
- Production readiness remains a local contract, not an external audit or
  deployment certification.
