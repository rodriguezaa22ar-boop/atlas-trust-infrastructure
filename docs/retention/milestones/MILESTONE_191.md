# Milestone 191: External Receipt Safety Regression

## Summary

M191 hardens the M190 external-project receipt pilot with synthetic negative
fixtures, reviewer-facing failure explanations, and metadata-only regression
coverage.

M191 does not change receipt semantics, hashing, canonicalization, replay behavior, runtime execution, UI, or server state.

The milestone is a safety regression milestone, not a feature milestone. It does
not change receipt semantics, hashing, canonicalization, replay behavior,
runtime execution, UI, server state, shell behavior, or source-system authority.

## Scope

- Added reviewer-facing external-project receipt failure guidance.
- Added synthetic negative event fixtures for fail-closed review cases.
- Documented how reviewers should interpret external receipt failures.
- Added focused Bats coverage for negative fixtures, forbidden-marker rejection,
  tamper rejection, replay order rejection, and no-overclaim failure wording.
- Added this retention note and milestone index row.

## Safety Boundary

M191 is docs/examples/tests only. It does not add runtime execution, live
integrations, API calls, webhooks, scanners, command semantics, shell behavior,
receipt schema changes, receipt hash changes, canonicalization changes, replay
changes, Atlas Node UI changes, server changes, database state, raw runtime
capture, approval execution, or autonomous authority.

The negative fixtures are synthetic and metadata-focused. They do not contain
secrets, tokens, credentials, private keys, request bodies, response bodies,
packet captures, raw prompts, raw model outputs, raw terminal logs, customer
data, payment data, private business records, private target records, or
unredacted evidence bodies.

## Reviewer Boundary

M191 clarifies that Atlas can fail closed on unsafe receipt metadata, missing
required fields, hash tampering, and caller-supplied chain ordering gaps.

It does not claim that Atlas proves source-system truth, legal sufficiency,
compliance approval, production approval, external audit completion,
certification, action correctness, artifact correctness, complete event
coverage, tamper-proof storage, or replacement of human judgment.

## Validation

- M191 opening guard: pass.
- `git diff --check`: pending.
- Focused M191 Bats: pending.
- `./bin/export-public-trust --check`: pending.
- `nix-shell --run './tools/atlas/bin/atlas v1 status --strict'`: pending.
- Full `nix-shell --run './bin/dev-qa'`: pending.
- No `__pycache__` / `*.pyc`: pending.

## Retention

- Branch: pending
- Commit: pending
- Tag: not created
- Reserved tag: `atlas-retention-m191`
