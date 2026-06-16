# Milestone 190: External Project Receipt Pilot

## Summary

M190 adds a small external-project receipt pilot that uses the existing
`generic.external_event.v1` import path and the existing `atlas.receipt.v1`
receipt verifier/replay engine.

The milestone makes the external-project proof boundary easier to review
without adding a new runtime system, live integration, source-system API
client, database, server, web UI, scanner, approval executor, or autonomous
agent behavior.

## Scope

- Added external-project receipt guidance.
- Added a synthetic external-project event fixture.
- Added a synthetic generated receipt fixture.
- Added a focused Bats regression covering import, verify, replay, fail-closed
  unsafe markers, metadata-only flags, missing fields, JSON validity, and
  no-overclaim documentation.
- Added this retention note and milestone index row.

## Safety Boundary

M190 is docs/examples/tests only. It does not add runtime behavior, shell
behavior, live integrations, network collection, source-system API calls,
webhooks, credentials, policy enforcement, approval workflow execution,
automatic approval, automatic escalation, evidence collection, database/server
or web UI behavior, autonomous execution, receipt semantic changes, hashing
changes, canonicalization changes, or replay behavior changes.

Atlas records and verifies metadata-only proof chains. It does not grant
permission, replace approval authorities, certify compliance, prove legal
sufficiency, guarantee action validity, prove complete event coverage, prove
actions outside Atlas did not happen, or replace human judgment.

## Receipt Boundary

The M190 external-project profile records:

- actor, project, system, action, capability, policy, approval, evidence, and
  artifact references;
- input and output hashes as metadata references;
- deterministic receipt hashes;
- known limitations and non-guarantees.

It does not store raw logs, raw prompts, raw model outputs, terminal buffers,
request bodies, response bodies, packet captures, credentials, tokens, private
keys, session cookies, customer data, payment data, private business records,
private target records, or unredacted evidence bodies.

## Validation

- Atlas Node pre-check: pending.
- W012 latest self-test: pending.
- `git diff --check`: pending.
- Changed shell syntax checks: pending.
- Focused M190 Bats: pending.
- `nix-shell --run './tools/atlas/bin/atlas v1 status --strict'`: pending.
- Full `nix-shell --run './bin/dev-qa'`: pending.
- No `__pycache__` / `*.pyc`: pending.

## Retention

- Branch: pending
- Commit: pending
- Tag: not created
- Reserved tag: `atlas-retention-m190`

