# Milestone 197: Retained Release Evidence Refresh Path

## Purpose

M197 defines the safe path for refreshing retained release evidence after
M193-M196 hardened policy source reporting, schema validation, pinned Nix, and
retained Nix compatibility behavior.

This milestone is docs/tests/runbook only. It does not generate new retained
release evidence and does not make Atlas production-ready.

## Context

Current `main` passes:

- `nix-shell --run './bin/dev-governance'`
- `nix-shell --run './bin/dev-qa'`
- `nix-shell --run './tools/atlas/bin/atlas v1 status --strict'`

`atlas production status --strict --explain` remains `not-ready` because the
latest retained production-candidate evidence is M140-era evidence bound to a
prior release commit.

That is correct. Stale retained evidence must keep production blocked.

## Changes

- Added `docs/retention/RELEASE_EVIDENCE_REFRESH.md`.
- Updated production and release trust documentation to point reviewers to the
  refresh runbook.
- Added regression coverage for the runbook and M197 boundary.

## Boundaries

- No production-ready claim is made.
- No new signed tag is created.
- No fake provenance is created.
- No fake production dry-run is created.
- No release packet or release artifact manifest is generated.
- M140 retained evidence is not rewritten.
- No production status gate is weakened.
- No runtime behavior is added.
- No Supabase, web UI, server state, database dependency, or deployment
  behavior is added.
- Metadata-only and public/private boundaries are preserved.

## Verification

Expected validation for this milestone:

```bash
git diff --check
./bin/export-public-trust --check
nix-shell --run './bin/dev-qa'
nix-shell --run './tools/atlas/bin/atlas v1 status --strict'
nix-shell --run './tools/atlas/bin/atlas production status --strict --explain'
```

Expected result:

- `dev-qa`: pass
- `v1 status`: pass
- `production status`: expected `not-ready`

Production status remains blocked until a later approved milestone creates and
verifies real retained release evidence for the current release commit.

## Next Step

M198 or a later approved milestone may execute the retained release evidence
refresh using the M197 runbook. It must use real QA, real V1 readiness, real
dry-run evidence, a real signed production-candidate tag, real provenance, and
a real release artifact manifest.
