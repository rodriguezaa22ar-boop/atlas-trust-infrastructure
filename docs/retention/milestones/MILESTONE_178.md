# Milestone 178: Approval Plane Draft

## Reviewed Commit

`7843a9b9058a526c96394c81cac8d575aedcada3` M177 policy plane safety
regression

## Purpose

Create the first Atlas approval-plane draft that defines how approvals,
reviewers, approval states, expiration, rejection, escalation, break-glass
documentation, and evidence outputs will be modeled before adding any live
approval engine or workflow execution.

M178 is the value step after the M177 policy-plane safety regression.

## Added

- Added `approval/approval-plane.yaml` as a metadata-only draft approval-plane
  contract.
- Added approval states for requested, approved, rejected, expired, revoked,
  stale, escalated, unsupported, and boundary violation outcomes.
- Added draft approval workflows for release exceptions, ticket transition
  proposals, cloud change proposals, AI-agent requested tool execution,
  production-readiness exceptions, sensitive business-flow changes, public
  export boundary review, and break-glass documentation review.
- Added `docs/governance/APPROVAL_PLANE_M178.md`.
- Updated the stable approval-plane docs and documentation index.
- Extended `bin/dev-approval` to validate the M178 draft contract.
- Added focused Bats coverage for the M178 approval-plane draft.

## Safety Result

- Approval engine execution remains disabled.
- Live approval workflows remain disabled.
- Automatic approval remains disabled.
- Break-glass execution remains disabled.
- Approval records remain metadata-only.
- Approval records do not grant authorization by themselves.
- Approval records do not prove the action was valid, legal compliance,
  production deployability, external completeness, or compliance.
- Sensitive raw content remains forbidden.

## Validation

- `git diff --check`: pass.
- `bash -n bin/dev-approval`: pass.
- `./bin/dev-approval`: pass.
- `./bin/dev-governance`: pass.
- Focused M178 approval plane draft Bats: pass.
- `./bin/export-public-trust --check`: pass.
- `nix-shell --run './bin/dev-qa'`: pass.

## Boundaries

- Docs/tests/schema and validation tooling only.
- No approval engine added.
- No approval workflow execution added.
- No live integration added.
- No credential handling added.
- No API calls added.
- No webhooks added.
- No network collectors added.
- No database/server/web UI added.
- No policy engine execution added.
- No adapter execution added.
- No automatic approval added.
- No automatic escalation added.
- No break-glass execution added.
- No receipt semantics changed.
- Known limitations preserved.
- Tag target: `atlas-retention-m178`.
