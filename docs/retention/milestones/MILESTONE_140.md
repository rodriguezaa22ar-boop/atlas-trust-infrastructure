# Milestone 140: Refresh Release Reviewer Evidence

## Commit

`18430ce9b00191d536096779d88398b2df01e320` Retain M139 receipt quickstart milestone

## Purpose

Regenerate and retain current release evidence so reviewer package generation
can pass against the current main commit without weakening stale-evidence
detection.

## Context

The full synthetic capability drill passed through receipt verification,
receipt replay, governance checks, synthetic operation trust-chain validation,
release packet verification, release replay, read-only checks, public export
checks, and fresh-clone reviewer simulation. It then failed correctly at
reviewer package generation because the latest retained release artifact
manifest still pointed at the older M121 release commit.

That failure is the intended behavior. Atlas must not package reviewer evidence
from a stale retained manifest.

## Retained Artifacts

- `docs/retention/releases/atlas-m140-refresh-release-reviewer-evidence.json`
- `docs/retention/releases/atlas-m140-refresh-release-reviewer-evidence.provenance.json`
- `docs/retention/releases/atlas-m140-refresh-release-reviewer-evidence.manifest.json`
- `docs/retention/production/PRODUCTION_DRY_RUN_2026-05-22_M140.md`
- `docs/retention/milestones/MILESTONE_140.md`
- Signed tag: `atlas-production-candidate-m140`

## Validation

- `git diff --check`: passed.
- `atlas release verify docs/retention/releases/atlas-m140-refresh-release-reviewer-evidence.json`: passed.
- `atlas release replay docs/retention/releases/atlas-m140-refresh-release-reviewer-evidence.json --json`: passed.
- `atlas release manifest-verify docs/retention/releases/atlas-m140-refresh-release-reviewer-evidence.manifest.json --commit 18430ce9b00191d536096779d88398b2df01e320`: passed.
- `atlas reviewer package full-capability-review`: passed.
- `nix-shell --run './bin/dev-qa'`: passed with 132/132 Bats plus lint, portability, and stress.

## Trust Impact

M140 restores reviewer package readiness by refreshing the retained release
artifact evidence for the current release commit. The stale-manifest guard
remains intact: reviewer packages only pass after the release packet, signed
provenance, production dry-run note, release artifact manifest, signing public
key, and milestone note all verify together.

## Boundaries

- This milestone refreshes release/reviewer evidence only.
- This milestone does not weaken reviewer package checks.
- This milestone does not bypass stale manifest detection.
- This milestone does not fake production readiness.
- This milestone does not add runtime behavior.
- This milestone does not add demo-site work.
- This milestone does not add agent behavior.
- The release evidence remains metadata-only.
- Production status remains a local Atlas contract and is not external audit,
  legal compliance, tamper-proof infrastructure, runtime safety proof, or
  production deployability proof.
- Tag target: `atlas-retention-m140`.
