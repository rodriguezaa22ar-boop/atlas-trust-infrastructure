# Milestone 182: Governance Plane Integration Map

## Reviewed Commit

`8b735a9d83dfba835d1663be6186efe92fd5b1d5` M181 evidence envelope safety regression

## Purpose

Create the first end-to-end governance plane integration map showing how the
Capability Manifest, Adapter Registry, Policy Plane, Approval Plane, and
Evidence Envelope connect.

M182 is the value step after completing the first governance-plane stack.

## Added

- Added `docs/governance/GOVERNANCE_PLANE_INTEGRATION_MAP_M182.md`.
- Linked the integration map from `docs/INDEX.md`.
- Added focused Bats coverage for the M182 integration map.
- Updated the milestone index.

## Value

- Explains the end-to-end modeled flow from action request or imported event to
  capability lookup, adapter classification, policy decision, approval state,
  evidence envelope, reviewer output, and replay later.
- Makes the five drafted governance planes understandable to contributors,
  reviewers, future users, and business/technical stakeholders.
- Distinguishes current contracts/schemas/examples/safety regressions from
  future runtime governance.
- Preserves bounded business value: clearer review, lower evidence
  reconstruction work, safer future connectors, privacy-preserving governance,
  stronger audit readiness, lower cost of trust without lowering standards, and
  proof without exposure.

## Safety Result

- M182 is architecture documentation only.
- Human judgment remains required for high-risk decisions.
- Approval records do not prove action validity.
- Policy decisions do not grant authorization by themselves.
- Evidence envelopes do not replace reviewer judgment.
- Metadata-only proof boundaries remain explicit.
- Failure and boundary states remain visible, including unknown capability,
  unknown adapter, boundary violation, expired/rejected approvals, missing,
  stale, unverifiable, or outside-Atlas evidence, and unsupported decisions.

## Validation

- `git diff --check`: pass.
- `./bin/dev-governance`: pass.
- Focused M182 Bats: pass.
- `./bin/export-public-trust --check`: pass.
- `nix-shell --run './bin/dev-qa'`: pass.

## Boundaries

- Docs/tests only.
- No runtime orchestration added.
- No action router added.
- No runtime policy enforcement added.
- No runtime evidence collection added.
- No automatic evidence capture added.
- No approval workflow execution added.
- No adapter execution added.
- No live integrations added.
- No credentials, API calls, webhooks, or network collectors added.
- No database/server/web UI added.
- No receipt semantics changed.
- No hashing/canonicalization/replay behavior changed.
- Known limitations preserved.
- Tag target: `atlas-retention-m182`.
