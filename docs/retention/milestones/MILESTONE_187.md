# Milestone 187: Public Source Alignment Safety Regression

## Summary

M187 protects the M186 public source alignment from overclaiming Atlas'
current maturity, weakening metadata-only boundaries, implying runtime
governance exists, or treating billion-dollar roadmap language as implemented
functionality.

M187 preserves Atlas as open proof infrastructure direction and a
metadata-first trust overlay for critical digital actions while keeping public
source docs clear that governance contracts, draft schemas, examples, and
validation helpers are not runtime engines unless a later milestone explicitly
implements that behavior.

## Scope

- Added focused regression coverage for the M186 public source docs.
- Locked the completed governance stack references in public-facing entry
  points.
- Locked the no-overclaim and metadata-only forbidden-content boundaries.
- Added a small README wording clarification that Atlas does not replace the
  existing systems it reviews.
- Updated the milestone index.

## Safety Boundary

M187 is docs/tests only. It adds no runtime behavior, shell behavior, receipt
semantic changes, hashing/canonicalization/replay behavior changes, policy
engine, approval engine, adapter execution, evidence collection, decision
engine, live integrations, credentials, API calls, webhooks, network
collectors, database/server/web UI, autonomous execution, production
certification, compliance claim, or external audit claim.

Atlas records and verifies metadata-only proof chains. It does not grant
permission, replace approval authorities, certify compliance, prove legal
sufficiency, guarantee action validity, prove complete event coverage, prove
actions outside Atlas did not happen, or replace human judgment.

## Safety Regression

The focused M187 regression protects:

- bounded roadmap/product direction language;
- governance contracts as non-runtime documentation;
- decision vocabulary terms as non-authorizing terminology;
- evidence envelopes as metadata-only schema contracts;
- approval and policy records as review support, not proof of legal,
  compliance, production, or action validity;
- metadata-only proof records that exclude raw sensitive content;
- lower cost of trust without lowering standards as bounded business value;
- proof without exposure as bounded privacy value;
- reviewer-readable proof and replay value without replacing human judgment.

## Validation

- Atlas Node `/api/ping`: pass, v2.11.0, local-only.
- W012 fast self-test: warn, 25/26 pass, 0 failed; vault mounted and
  `vault_anchor_match` true. Warning was `atlas_core_untouched` because the
  M187 working tree was intentionally dirty before commit.
- `git diff --check`: pass.
- `git diff --cached --check`: pass.
- `./bin/export-public-trust --check`: pass, 586 allowed files, 0 forbidden
  paths, 0 private markers.
- `./bin/dev-governance`: pass.
- `./bin/dev-decisions`: pass.
- Focused M187 Bats on builder isolated clone: pass, 1/1.
- Builder isolated-clone `nix-shell --run './bin/dev-qa'`: pass, 178/178 plus
  lint/governance/portability/stress, `qa: ok`.
- No `__pycache__` / `*.pyc` found locally or on the builder isolated clone.

## Retention

- Branch: `m187-public-source-alignment-safety`
- Commit: pending
- Tag: not created
- Reserved tag: `atlas-retention-m187`
