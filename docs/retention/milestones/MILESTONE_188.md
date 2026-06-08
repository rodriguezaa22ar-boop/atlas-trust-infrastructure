# Milestone 188: Atlas Master Bible

## Summary

M188 adds the Atlas Master Bible: a single high-level orientation document for
Atlas' mission, proof model, governance stack, operating doctrine, business
value, enterprise direction, and known limitations.

The document positions Atlas as metadata-first proof infrastructure for
critical digital actions and a trust overlay above existing systems, while
preserving the public/private repository boundary, metadata-only proof records,
local verification, reviewer-readable replay, and no-overclaim language.

## Scope

- Added `docs/ATLAS_MASTER_BIBLE.md`.
- Linked the Master Bible from `docs/INDEX.md`.
- Added focused M188 Bats coverage.
- Added this retention note and milestone index entry.

## Safety Boundary

M188 is docs/tests only. It adds no runtime behavior, shell behavior, receipt
semantic changes, hashing/canonicalization/replay behavior changes, policy
engine, approval engine, adapter execution, evidence collection, decision
engine, live integrations, credentials, API calls, webhooks, network
collectors, database/server/web UI, autonomous execution, production
certification, compliance claim, or external audit claim.

Atlas records and verifies metadata-only proof chains. It does not grant
permission, replace approval authorities, certify compliance, prove legal
sufficiency, guarantee action validity, prove complete event coverage, prove
actions outside Atlas did not happen, or replace human judgment.

## Value

The Master Bible gives new contributors, reviewers, technical mentors,
business readers, future collaborators, investors/advisors, and
security/audit-minded readers one bounded orientation path before they move
into detailed docs, schemas, tests, receipts, and retained evidence.

It preserves:

- trust should come with a receipt;
- proof without exposure;
- lower cost of trust without lowering standards;
- privacy-preserving governance;
- governance contracts before runtime automation;
- reviewer clarity before product hype.

## Validation

- Atlas Node `/api/ping`: pass, v2.11.0, local-only.
- W012 fast self-test: warn, 25/26 pass, 0 failed; vault mounted and
  `vault_anchor_match` true. Warning was `atlas_core_untouched` because the
  M188 working tree was intentionally dirty before commit.
- `git diff --check`: pass.
- `git diff --cached --check`: pass.
- `./bin/export-public-trust --check`: pass, 588 allowed files, 0 forbidden
  paths, 0 private markers.
- `./bin/dev-governance`: pass.
- `./bin/dev-decisions`: pass.
- Focused M188 Bats on builder isolated clone: pass, 1/1.
- Builder isolated-clone `nix-shell --run './bin/dev-qa'`: pass, 179/179 plus
  lint/governance/portability/stress, `qa: ok`.
- No `__pycache__` / `*.pyc` found locally or on the builder isolated clone.

## Retention

- Branch: `m188-atlas-master-bible`
- Commit: pending
- Tag: not created
- Reserved tag: `atlas-retention-m188`
