# Milestone 77: Atlas Business Flow Packet Verification

## Release Commit

`cd9d00c22a16dbbe7e8a51dca79a51afc2149aa5` Add Atlas business flow verification

## Purpose

Make Business Flow Evidence packets independently checkable against the active
operation, flow record, evidence links, retained evidence files, freshness, and
metadata-only guardrails.

## Added

- `atlas flow verify <flow> [packet-name]`.
- Read-only Markdown Business Flow Evidence packet verification.
- Packet checks for schema marker, metadata-only marker, raw-evidence embedding
  marker, operation, target, flow ID, flow record hash, and generation time.
- Evidence-link checks for operation link presence, evidence link count,
  freshness, evidence IDs, retained paths, SHA-256 hashes, classification, and
  redaction state.
- Retained evidence file checks that recompute SHA-256 and detect tampering.
- Forbidden raw-content marker scan for retained flow packets.
- Stale classification when linked evidence changes after packet generation or
  the packet evidence-link count no longer matches current links.
- Negative tests for missing packet, forbidden packet content, stale packet,
  read-only verification behavior, and retained evidence hash mismatch.
- Documentation updates across command reference, Business Flow Evidence spec,
  packet schema, packet parity matrix, trust object model, trust infrastructure
  direction, roadmap, Atlas README, and blueprint.

## Retained Evidence

- `docs/retention/releases/atlas-m77-business-flow-verify.json`
- `docs/retention/releases/atlas-m77-business-flow-verify.provenance.json`
- `docs/retention/production/PRODUCTION_DRY_RUN_2026-04-27_M77.md`
- Signed tag: `atlas-production-candidate-m77`

## Verified

- `bash -n tools/atlas/bin/atlas`
- `bash -n tools/atlas/lib/flows.sh`
- `git diff --check`
- `nix-shell --run 'bats --filter "business-flow evidence|atlas flow|atlas help|schema docs|packet format parity|atlas trust" tests/atlas.bats'`: `11/11`
- `nix-shell --run 'bats --filter "atlas flow verify checks" tests/atlas.bats'`: `1/1`
- `nix-shell --run './bin/dev-qa'`: `90/90`, lint ok, stress ok
- `./tools/atlas/bin/atlas release packet atlas-m77-business-flow-verify --json --qa-status pass --qa-command "nix-shell --run './bin/dev-qa'" --qa-note "dev-qa passed with 90/90 tests, lint ok, and stress ok before M77 business-flow verification release packet"`
- `./tools/atlas/bin/atlas release verify docs/retention/releases/atlas-m77-business-flow-verify.json --commit cd9d00c`: verified
- `./tools/atlas/bin/atlas release replay docs/retention/releases/atlas-m77-business-flow-verify.json`: QA ok, v1 status ok, release verify ok
- `git tag -v atlas-production-candidate-m77`: good signature

## Repo State

- Release commit: `cd9d00c22a16dbbe7e8a51dca79a51afc2149aa5`.
- Release packet retained.
- Release provenance packet retained.
- Production dry-run note retained.
- Business Flow Evidence packet verification is implemented and covered by
  positive and negative tests.
- Business Flow Evidence JSON parity, finding links, validation links,
  retention links, schema stabilization, and optional readiness integration
  remain planned later steps.
