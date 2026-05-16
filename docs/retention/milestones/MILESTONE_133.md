# Milestone 133: Receipt Replay + Ledger Binding

## Commit

`c67f1eb75da314da9a0528531bc0b374daed0e5a` M133 add receipt replay ledger binding

## Purpose

Bind Atlas Receipt v1 records into replayable append-only local chains without
introducing hidden state or execution behavior.

## Added

- Added `atlas receipt replay <receipt-file> [receipt-file ...] [--json]`
- Added deterministic `atlas.receipt_replay.v1` JSON replay output
- Added local chain validation for `prev_hash -> event_hash` linkage
- Added linked receipt-chain reviewer example
- Added receipt replay schema documentation and schema-freeze classification
- Added regression coverage for valid chain replay, broken `prev_hash`,
  missing `prev_hash`, stale `event_hash`, metadata-only rejection, and
  read-only no-runtime-mutation behavior

## Validation

- PR #27: merged.
- Public GitHub PR QA: success.
- Public GitHub PR CodeQL: success.
- Public GitHub PR Release Trust: success.
- Public GitHub workflow analysis: success.
- `git diff --check`: passed.
- Focused builder Bats receipt/schema-freeze filter: passed.
- Post-merge builder `nix-shell --run './bin/dev-qa'`: passed.

## Security Baseline

- Report:
  `/home/ao/workspace/projects/labs/parrot-to-nix-security-current/parrot-to-nix-security-test-report.txt`
- SHA-256:
  `7a674864bca5ae9ff574268867c1e25502960d166b31115f592d2247775d003c`

The baseline was a named-host Parrot-to-Nix check for `atlas-console` to
`atlas-builder`. It did not include the iPhone, subnet scanning, exploitation,
credential attacks, fuzzing, denial-of-service testing, payload delivery,
persistence, or stealth behavior.

## Trust Impact

M133 moves receipts from isolated metadata-only proof objects toward replayable
local proof chains. Reviewers can now verify a caller-provided receipt sequence
and retain the final chain checkpoint without relying on a database, server,
network collector, automation runner, or hidden state.

## Boundaries

- This milestone is local-only and metadata-only.
- Receipt replay is read-only and must not create runtime layout or append
  operation ledger events.
- Receipt replay does not prove external artifact availability, human intent,
  legal compliance, artifact correctness, authorization, production readiness,
  external audit, or tamper-proof infrastructure.
- This milestone does not add a database, server, web UI, agent execution,
  network collector, automation runner, exploit workflow, credential workflow,
  fuzzing workflow, or denial-of-service workflow.
