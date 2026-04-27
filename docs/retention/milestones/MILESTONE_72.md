# Milestone 72: Atlas Business Flow Evidence Links

## Release Commit

`85c68f9e8cedce4eb6dcfb385095962631abe9b1` Add Atlas business flow evidence links

## Purpose

Let optional Business Flow Evidence records point to existing Atlas evidence in
an active operation without copying raw evidence or embedding sensitive business
content.

## Added

- `atlas flow link-evidence <flow> <evidence-id>`.
- Operation flow links under `sessions/<operation>/business_flows.ndjson`.
- Flow evidence links under `sessions/<operation>/flow_evidence.ndjson`.
- `atlas.business_flow_link.v1` metadata records.
- `atlas.flow_evidence_link.v1` metadata records.
- Ledger event `flow.evidence_linked`.
- Tests for active-operation enforcement, missing evidence failure,
  metadata-only link shape, absence of raw evidence/source path fields, and
  ledger recording.
- Help, command reference, Atlas README, Business Flow Evidence docs, and
  blueprint updates.

## Retained Evidence

- `docs/retention/releases/atlas-m72-business-flow-evidence-links.json`
- `docs/retention/releases/atlas-m72-business-flow-evidence-links.provenance.json`
- `docs/retention/production/PRODUCTION_DRY_RUN_2026-04-27_M72.md`
- Signed tag: `atlas-production-candidate-m72`

## Verified

- `bash -n tools/atlas/bin/atlas tools/atlas/lib/flows.sh`
- `git diff --check`
- `nix-shell --run './bin/dev-lint'`: lint ok
- `nix-shell --run 'bats --filter "business-flow evidence|atlas flow|atlas help groups|root README" tests/atlas.bats'`: `5/5`
- `nix-shell --run './bin/dev-qa'`: `85/85`, lint ok, stress ok
- `./tools/atlas/bin/atlas release packet atlas-m72-business-flow-evidence-links --json --qa-status pass --qa-note "dev-qa passed before M72 business-flow evidence links release packet"`
- `./tools/atlas/bin/atlas release verify docs/retention/releases/atlas-m72-business-flow-evidence-links.json --commit 85c68f9`: verified
- `git tag -v atlas-production-candidate-m72`: good signature

## Real-Business Smoke Test

Metadata-only evidence links were created locally for:

- Ascend and Defend Academy service delivery.
- Execution OS SaaS subscription.

The smoke test linked each flow to a non-secret Atlas evidence artifact and
confirmed the link records contain only evidence ID, kind, retained path,
SHA-256, classification, redaction state, operation, target, timestamp, and
metadata-only notes. No secrets, customer records, payment data, request/response
bodies, tokens, source paths, raw evidence fields, or evidence bodies were stored
in the flow link records.

## Repo State

- Release commit: `85c68f9e8cedce4eb6dcfb385095962631abe9b1`.
- Release packet retained.
- Release provenance packet retained.
- Production dry-run note retained.
- Business Flow Evidence remains optional.
- `atlas flow packet`, `atlas flow verify`, and readiness integration remain
  planned.
- Production readiness remains a local contract, not an external audit or
  deployment certification.
