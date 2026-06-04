# Milestone 176: Policy Plane Draft

## Reviewed Commit

`576046958612b1c6bada844a60aef17b2ae33e50` M175 adapter registry safety
regression

## Purpose

Create the first Atlas policy-plane draft that defines how Atlas can model
capability, adapter, approval, and evidence decisions without adding runtime
policy enforcement.

M176 is the value step after the M175 adapter registry safety hardening step.

## Added

- Added `policy/policy-plane.yaml` with `schema_version:
  atlas.policy_plane.v1`, draft status, `default_decision: deny`,
  `runtime_enforcement_enabled: false`, `policy_engine_enabled: false`,
  `live_integrations_enabled: false`, and `metadata_only: true`.
- Added policy inputs for actor, capability, adapter, action, resource, scope,
  risk tier, approval state, evidence references, and request context.
- Added draft decision vocabulary for allow, deny, approval required, evidence
  required, unsupported, unknown capability, unknown adapter, and boundary
  violation.
- Added draft policy bundles for default deny, known capability, known adapter,
  metadata-only boundary, import-first adapters, proposal approval path,
  AI-agent requester-not-authority, release verify read-only, public export
  boundary, and evidence required for decision.
- Updated `bin/dev-policy` to validate the draft policy-plane contract while
  preserving existing policy fixture validation.
- Added `docs/governance/POLICY_PLANE_M176.md`.
- Updated the stable policy-plane doc and docs index.
- Added focused Bats coverage for the M176 policy-plane draft.
- Updated the milestone index.

## Validation

- `git diff --check`: pass.
- Focused M176 policy plane Bats: pass.
- `bash -n bin/dev-policy`: pass.
- `./bin/dev-policy`: pass.
- `./bin/dev-governance`: pass.
- `./bin/export-public-trust --check`: pass.
- `nix-shell --run './bin/dev-qa'`: pass.

## Boundaries

- Docs/tests/schema/tooling only.
- No Atlas runtime policy enforcement added.
- No policy engine execution added.
- No OPA/Rego runtime execution added.
- No Cedar runtime execution added.
- No adapter execution added.
- No live integration added.
- No credential handling added.
- No API calls added.
- No webhooks added.
- No network collectors added.
- No mutation authority added.
- No approval engine added.
- No database/server/web UI added.
- No receipt semantics changed.
- Existing external systems remain the source of their own operational truth.
- Known limitations preserved.
- Tag target: `atlas-retention-m176`.
