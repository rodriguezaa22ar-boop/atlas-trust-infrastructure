# Milestone 186: Public Source Alignment

## Summary

M186 aligns Atlas' highest-priority public source docs with the completed
M172-M185 governance stack and the open proof infrastructure direction.

It updates the public entry points to describe Atlas as metadata-first proof
infrastructure for critical digital actions while preserving the public/private
repository boundary, metadata-only proof boundary, and no-overclaim language.

## Scope

- Updated public source entry docs for the current governance direction.
- Added the completed governance stack to public-facing documentation:
  capability, adapter, policy, approval, evidence, integration map, and
  decision vocabulary.
- Added bounded open proof / product-direction language.
- Added focused Bats coverage for public-source alignment.
- Updated the milestone index.

## Safety Boundary

M186 is docs/tests only. It adds no runtime behavior, receipt semantic changes,
hashing/canonicalization/replay behavior changes, policy engine, approval
engine, adapter execution, evidence collection, decision engine, live
integration, credentials, API calls, webhooks, network collectors,
database/server/web UI, autonomous execution, production certification,
compliance claim, or external audit claim.

Atlas records and verifies metadata-only proof chains. It does not grant
permission, replace approval authorities, certify compliance, prove legal
sufficiency, guarantee action validity, prove complete event coverage, prove
actions outside Atlas did not happen, or replace human judgment.

## Public Alignment

- README now points to the governance stack and bounded open proof direction.
- AGENTS now treats governance-plane alignment, public source alignment, Open
  Core receipt alignment, and release trust as current priorities.
- CONTRIBUTING now names governance validation helpers and the metadata-only /
  no-overclaim expectations for governance changes.
- The docs index and stale public source docs now expose the completed
  governance stack without implying runtime enforcement.

## Validation

- Atlas Node `/api/ping`: pass, v2.11.0, local-only.
- W012 fast self-test: warn, 25/26 pass, 0 failed; vault mounted and
  `vault_anchor_match` true. Warning was `atlas_core_untouched` because the
  M186 working tree was intentionally dirty before commit.
- `git diff --check`: pass.
- `git diff --cached --check`: pass.
- `./bin/export-public-trust --check`: pass, 585 allowed files, 0 forbidden
  paths, 0 private markers.
- `./bin/dev-governance`: pass.
- `./bin/dev-decisions`: pass.
- Focused M186 Bats on builder isolated clone: pass, 1/1.
- Builder isolated-clone `nix-shell --run './bin/dev-qa'`: pass, 177/177 plus
  lint/governance/portability/stress, `qa: ok`.
- No `__pycache__` / `*.pyc` found locally or on the builder isolated clone.

## Retention

- Branch: `m186-public-source-alignment`
- Commit: pending
- Tag: not created
- Reserved tag: `atlas-retention-m186`
