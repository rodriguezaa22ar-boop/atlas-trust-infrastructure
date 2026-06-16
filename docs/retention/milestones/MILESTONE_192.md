# Milestone 192: External Receipt Reviewer Output

## Summary

M192 adds reviewer-facing plain-English output for external-project receipts so
a reviewer can understand what the receipt verifies, what it does not verify,
what evidence references exist, and what decision remains outside Atlas.

M192 does not change receipt semantics, hashing, canonicalization, replay
behavior, runtime execution, UI, or server state.

## Scope

- Added external receipt reviewer-output guidance.
- Added a synthetic metadata-only reviewer-output example fixture.
- Updated the external-project receipt example README.
- Added focused Bats coverage for reviewer-output wording, metadata-only
  boundary language, reference visibility, receipt verification parity, and
  no-overclaim language.
- Added this retention note and milestone index row.

## Safety Boundary

M192 is docs/examples/tests only. It does not add runtime execution, live
integrations, API calls, webhooks, scanners, command semantics, shell behavior,
receipt schema changes, receipt hash changes, canonicalization changes, replay
changes, Atlas Node UI changes, server changes, database state, raw runtime
capture, approval execution, or autonomous authority.

The reviewer-output fixture is synthetic and metadata-only. It does not contain
secrets, tokens, credentials, private keys, request bodies, response bodies,
packet captures, raw prompts, raw model outputs, raw terminal logs, customer
data, payment data, private business records, private target records, or
unredacted evidence bodies.

## Reviewer Boundary

M192 clarifies how a reviewer should read an external-project receipt. Atlas can
show local schema, hash, metadata-only, reference, and replay-linkage facts. It
does not prove source-system truth, legal sufficiency, compliance approval,
production approval, external audit completion, certification, action
correctness, artifact correctness, complete event coverage, tamper-proof
storage, or replacement of human judgment.

## Validation

- M192 opening guard: pass.
- `git diff --check`: pending.
- Focused M192 Bats: pending.
- `./bin/export-public-trust --check`: pending.
- `./tools/atlas/bin/atlas receipt verify examples/receipt/external-project/minimal-receipt.json --json`: pending.
- `nix-shell --run './tools/atlas/bin/atlas v1 status --strict'`: pending.
- Full `nix-shell --run './bin/dev-qa'`: pending.
- No `__pycache__` / `*.pyc`: pending.

## Retention

- Branch: pending
- Commit: pending
- Tag: not created
- Reserved tag: `atlas-retention-m192`
