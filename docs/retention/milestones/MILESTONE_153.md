# Milestone 153: GitHub Actions Event Proof Package

## Reviewed Commit

`3a6ddccc3d9014ed41d5796a56be3503a60a0b4b` M152 merged checkpoint

## Purpose

Create a reviewer-facing proof package for the GitHub Actions run/check
metadata receipt path using only the existing `generic.external_event.v1`
adapter and existing receipt verify/replay behavior.

## Added

- Added `docs/reviews/GITHUB_ACTIONS_EVENT_PROOF_PACKAGE_M153.md`.
- Updated `docs/INDEX.md`.
- Updated `docs/retention/MILESTONE_INDEX.md`.
- Added focused Bats coverage proving the proof package references the GitHub
  Actions run/check examples, M151 candidate, M152 security regression,
  existing generic adapter, receipt import, receipt verify, receipt replay,
  metadata-only boundary, non-guarantees, known limitations, and reviewer
  checklist.
- Verified the proof package commands import, verify, and replay the linked
  GitHub Actions run/check receipts.

## Validation

- Atlas Node pre-check: Current State Ready, 0 blockers, 0 warnings; W012
  self-test passed, 25/25.
- `git diff --check`: pass.
- Focused M153 Bats: pass, 1/1.
- `./bin/export-public-trust --check`: pass, Allowed files 517, Forbidden
  paths 0, Private markers 0.
- `nix-shell --run './bin/dev-qa'`: pass, 145/145 Bats plus lint,
  capabilities, adapters, policy, approval, evidence, portability, and stress;
  `qa: ok`.

## Trust Impact

M153 packages the M151-M152 GitHub Actions event receipt path into one
reviewer-facing proof bundle without adding live GitHub integration or
expanding runtime behavior.

The package keeps GitHub Actions metadata as a local-file, metadata-only event
source. Atlas remains a receipt verifier, not a GitHub client, webhook
collector, action runner, approval authority, or source-system truth engine.

## Boundaries

- Docs/tests only.
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
- No runtime behavior added.
- No production claim.
- No receipt semantics changed.
- No receipt verification, replay, canonicalization, release, or reviewer gate
  weakened.
- GitHub Actions metadata is an event source only.
- Atlas remains verifier, not authority.
- Human and policy remain authority.
- Generated GitHub Actions receipts verify.
- Linked GitHub Actions receipts replay.
- `metadata_only=true` preserved.
- `raw_artifacts_embedded=false` preserved.
- Known limitations visible.
- Tag target: `atlas-retention-m153`.
