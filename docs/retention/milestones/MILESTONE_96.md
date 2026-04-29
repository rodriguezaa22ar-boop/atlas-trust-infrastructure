# Milestone 96: Operation Flow Assurance Completeness Hardening

## Release Commit

`8fcc50b9b8aa71ba340fe10df2572b65158fae9d` Harden operation business flow assurance rollup

## Purpose

Harden the operation trust-chain Business Flow Evidence rollup so linked flows
fail visibly when flow links are malformed, flow records are missing, flow
packets are missing, or retained flow packets are stale.

## Added

- Packet status in operation trust-chain per-flow assurance summaries:
  - `current`
  - `stale`
  - `missing`
  - `blocked`
  - `not-recorded`
- Packet metadata in per-flow summaries:
  - packet format
  - packet path
  - packet generated timestamp
  - latest material flow timestamp
- Metadata-only `issues[]` arrays for per-flow assurance gaps.
- NDJSON line-count fallback so malformed business-flow links are still visible
  in aggregate operation trust-chain counts.
- Matching packet freshness checks across JSON and Markdown flow packets.
- Count-drift checks so packets become stale when linked evidence, findings,
  validation, approvals, or retention references change after packet generation.
- Negative Bats coverage for stale packets, missing packets, malformed flow
  links, missing flow records, and read-only ledger behavior.
- Schema documentation for packet status, packet metadata, and issues arrays.

## Verified

- `bash -n tools/atlas/lib/trust.sh`
- `bash -n tools/atlas/bin/atlas`
- `git diff --check`
- `nix-shell --run 'bats --filter "atlas op trust-chain surfaces business-flow evidence context read-only|atlas op trust-chain business-flow assurance flags stale missing and malformed flow state|schema docs pin implemented Atlas JSON contracts" tests/atlas.bats'`: `3/3`
- `nix-shell --run './bin/dev-qa'`: `101/101`, lint ok, stress ok

## Repo State

- Business Flow Evidence remains optional and non-blocking.
- Operation trust-chain flow assurance remains read-only and metadata-only.
- Malformed or incomplete flow evidence now appears as explicit rollup state
  instead of being hidden by packet counts.
- No target-touching behavior was added.
- No production-ready, external audit, payment verification, legal compliance,
  or third-party assurance claim is made by this milestone.
